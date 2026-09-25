import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/cache/cache_data.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Dio interceptor for automatic response caching with generic type support
///
/// Deduplication of the underlying network call is NOT handled here: on a
/// cache miss, [_performRequest] re-issues the request through [AppDio],
/// which is deliberately ordered so [RequestDeduplicationInterceptor] (see
/// network/request_deduplication_manager.dart) runs right after this
/// interceptor and coalesces concurrent in-flight duplicates. Keeping a
/// second, independent deduplicator here previously caused every cache-miss
/// GET to be bookkept by two different in-flight-request maps at once.
class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager = CacheManager();

  // Tracks cache keys currently being checked so concurrent duplicate
  // requests for the same key (later coalesced by
  // RequestDeduplicationInterceptor) don't each print their own
  // 'cache_check' log line. Purely a logging dedup — every call still runs
  // its own independent cache lookup exactly as before.
  final Set<String> _inFlightCacheChecks = {};

  CacheInterceptor({
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip caching for certain requests
    if (_shouldSkipCaching(options)) {
      if (_isBlockListEndpoint(options.path)) {
        await _cacheManager.invalidatePattern(ApiConstants.blockList);
      }
      handler.next(options);
      return;
    }

    final config = CacheConfigs.getConfigForEndpoint(options.path);
    if (config == null) {
      // Not allow-listed for caching — always go straight to the network.
      handler.next(options);
      return;
    }

    final cacheKey = _generateCacheKey(options);

    final isFirstInFlight = _inFlightCacheChecks.add(cacheKey);
    if (isFirstInFlight) {
      AppLogger.debug(
        'CacheInterceptor',
        'cache_check',
        data: {'endpoint': options.path, 'cacheKey': cacheKey},
      );
    }

    try {
      // Try to get cached data with stale-while-revalidate
      final cacheResult = await _cacheManager.getWithStaleRevalidate<CacheData>(
        cacheKey,
        (data) =>
            _safeCacheDataParse(
              data,
              context: 'CacheInterceptor.getWithStaleRevalidate',
            ) ??
            CacheData.fromEmpty(),
        config,
        () => _performRequest(options),
        toJson: (data) => data.toJson(),
      );

      if (cacheResult.hasData && !cacheResult.isStale) {
        if (isFirstInFlight) {
          AppLogger.debug(
            'CacheInterceptor',
            'cache_hit',
            data: {
              'endpoint': options.path,
              'type': cacheResult.data!.dataType,
            },
          );
        }

        // Return cached response with original data type
        final cachedResponse = Response(
          data: _extractOriginalData(cacheResult.data!),
          statusCode: 200,
          requestOptions: options,
          extra: {'fromCache': true, 'cacheType': cacheResult.data!.dataType},
        );
        handler.resolve(cachedResponse);
        return;
      }

      if (cacheResult.hasData && cacheResult.isStale) {
        if (isFirstInFlight) {
          AppLogger.debug(
            'CacheInterceptor',
            'cache_stale',
            data: {
              'endpoint': options.path,
              'type': cacheResult.data!.dataType,
            },
          );
        }

        // Return stale data while refreshing in background
        final staleResponse = Response(
          data: _extractOriginalData(cacheResult.data!),
          statusCode: 200,
          requestOptions: options,
          extra: {
            'fromCache': true,
            'isStale': true,
            'cacheType': cacheResult.data!.dataType,
          },
        );
        handler.resolve(staleResponse);
        return;
      }

      // No cached data, proceed with request
      handler.next(options);
    } finally {
      if (isFirstInFlight) {
        _inFlightCacheChecks.remove(cacheKey);
      }
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Skip caching for certain responses
    if (_shouldSkipCaching(response.requestOptions)) {
      if (_isBlockListEndpoint(response.requestOptions.path)) {
        await _cacheManager.invalidatePattern(ApiConstants.blockList);
      }
      handler.next(response);
      return;
    }

    // Only cache successful GET requests that are explicitly allow-listed.
    final config = CacheConfigs.getConfigForEndpoint(
      response.requestOptions.path,
    );
    if (config != null &&
        response.requestOptions.method.toUpperCase() == 'GET' &&
        (response.statusCode ?? 0) >= 200 &&
        (response.statusCode ?? 0) < 300) {
      final cacheKey = _generateCacheKey(response.requestOptions);

      // Create cache data wrapper based on response type
      final cacheData = _createCacheData(response.data);

      await _cacheManager.put(
        cacheKey,
        cacheData,
        config,
        toJson: (data) => data.toJson(),
      );

      AppLogger.debug(
        'CacheInterceptor',
        'cache_write',
        data: {
          'endpoint': response.requestOptions.path,
          'type': cacheData.dataType,
        },
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isBlockListEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    if (_shouldSkipCaching(err.requestOptions)) {
      handler.next(err);
      return;
    }

    // Try to return stale data on network errors
    final config = CacheConfigs.getConfigForEndpoint(err.requestOptions.path);
    if (config != null && _shouldReturnStaleOnError(err)) {
      final cacheKey = _generateCacheKey(err.requestOptions);

      final cached = await _cacheManager.get<CacheData>(
        cacheKey,
        (data) =>
            _safeCacheDataParse(data, context: 'CacheInterceptor.onError') ??
            CacheData.fromEmpty(),
        config,
      );

      if (cached != null) {
        AppLogger.debug(
          'CacheInterceptor',
          'cache_fallback_on_error',
          data: {'endpoint': err.requestOptions.path, 'type': cached.dataType},
        );

        final staleResponse = Response(
          data: _extractOriginalData(cached),
          statusCode: 200,
          requestOptions: err.requestOptions,
          extra: {
            'fromCache': true,
            'isStale': true,
            'fromError': true,
            'cacheType': cached.dataType,
          },
        );
        handler.resolve(staleResponse);
        return;
      } else {
        AppLogger.debug(
          'CacheInterceptor',
          'cache_fallback_unavailable',
          data: {'endpoint': err.requestOptions.path},
        );
      }
    }

    handler.next(err);
  }

  /// Re-issues the request through the rest of the interceptor chain on a
  /// cache miss. [RequestDeduplicationInterceptor] (registered after this
  /// interceptor in [AppDio]) coalesces this with any other in-flight
  /// duplicate of the same request.
  Future<CacheData> _performRequest(RequestOptions options) async {
    final dio = AppDio.getInstance();
    try {
      final requestOptions = options.copyWith();
      requestOptions.extra = Map<String, dynamic>.from(options.extra);
      requestOptions.extra['skipCache'] = true;

      final response = await dio.fetch(requestOptions);

      final cacheData = _createCacheData(response.data);
      AppLogger.debug(
        'CacheInterceptor',
        'fresh_request_succeeded',
        data: {'endpoint': options.path, 'type': cacheData.dataType},
      );
      return cacheData;
    } catch (e) {
      AppLogger.warning(
        'CacheInterceptor',
        'fresh_request_failed',
        data: {'endpoint': options.path, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Generates a unique cache key for the request
  /// CRITICAL: Never include request body in cache key to prevent 405 errors
  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write('${options.method}:${options.path}');

    // Add query parameters only (never request body)
    if (options.queryParameters.isNotEmpty) {
      final sortedParams = Map<String, dynamic>.fromEntries(
        options.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      buffer.write('?${sortedParams.toString()}');
    }

    // Namespace by account so a cache entry from one logged-in user is never
    // served to another. Falls back to a generic suffix only when no user id
    // is known yet (e.g. a request fired before AuthStateManager finishes
    // initializing) rather than silently sharing one bucket across accounts.
    if (options.headers.containsKey('Authorization')) {
      final userId = AuthStateManager().currentUserId;
      buffer.write('_user:${(userId == null || userId.isEmpty) ? 'unknown' : userId}');
    }

    return buffer.toString();
  }

  /// Determines if a request should skip caching
  bool _shouldSkipCaching(RequestOptions options) {
    final skipPaths = {
      '/auth/',
      '/logout',
      '/refresh',
      '/upload',
      '/delete',
      '/update',
      '/create',
      'posts/drafts',
      'drafts',
    };

    final method = options.method.toUpperCase();
    final isWriteOperation =
        method == 'POST' ||
        method == 'PUT' ||
        method == 'DELETE' ||
        method == 'PATCH';

    return isWriteOperation ||
        _isBlockListEndpoint(options.path) ||
        skipPaths.any((path) => options.path.contains(path)) ||
        options.extra['skipCache'] == true ||
        options.extra['bypassCache'] == true ||
        options.extra['noCache'] == true;
  }

  bool _isBlockListEndpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return normalizedPath.startsWith(ApiConstants.blockList);
  }

  /// Creates appropriate CacheData wrapper based on response type
  CacheData _createCacheData(dynamic data) {
    if (data == null) {
      return CacheData.fromEmpty();
    }

    if (data is Map<String, dynamic>) {
      // Check if it's a nested response (pagination wrapper)
      if (data.containsKey('results') ||
          data.containsKey('data') ||
          data.containsKey('messages')) {
        return CacheData.fromNested(data);
      } else {
        return CacheData.fromMap(data);
      }
    }

    if (data is List) {
      return CacheData.fromList(data);
    }

    // Try to convert other types to map
    final safeMap = SafeParsingHelpers.safeMapParse(
      data,
      context: '_createCacheData',
    );
    if (safeMap.isNotEmpty) {
      return CacheData.fromMap(safeMap);
    }

    // Try to convert to list
    final safeList = SafeParsingHelpers.safeListParse(
      data,
      context: '_createCacheData',
    );
    if (safeList.isNotEmpty) {
      return CacheData.fromList(safeList);
    }

    AppLogger.debug(
      'CacheInterceptor',
      'cache_data_fallback_empty',
      data: {'actualType': data.runtimeType.toString()},
    );
    return CacheData.fromEmpty();
  }

  /// Safely parse CacheData from JSON
  CacheData? _safeCacheDataParse(dynamic data, {String? context}) {
    if (data == null) {
      return null;
    }

    if (data is CacheData) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      try {
        return CacheData.fromJson(data);
      } catch (e) {
        AppLogger.warning(
          'CacheInterceptor',
          'cache_data_parse_failed',
          data: {'context': context ?? 'Unknown', 'error': e.toString()},
        );
        return null;
      }
    }

    AppLogger.warning(
      'CacheInterceptor',
      'cache_data_type_mismatch',
      data: {
        'context': context ?? 'Unknown',
        'actualType': data.runtimeType.toString(),
      },
    );
    return null;
  }

  /// Extract original data from CacheData wrapper
  dynamic _extractOriginalData(CacheData cacheData) {
    return cacheData.data;
  }

  bool _shouldReturnStaleOnError(DioException err) {
    // Return stale data on network errors but not on auth errors
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode ?? 0) >= 500;
  }
}
