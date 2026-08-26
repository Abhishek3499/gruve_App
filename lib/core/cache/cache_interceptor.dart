import 'package:dio/dio.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Generic cache data wrapper for type-safe serialization
class CacheData {
  final dynamic data;
  final String dataType; // 'map', 'list', 'nested', 'empty'
  final DateTime timestamp;

  CacheData({
    required this.data,
    required this.dataType,
  }) : timestamp = DateTime.now();

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'dataType': dataType,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Deserialize from JSON
  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData(
      data: json['data'],
      dataType: json['dataType'] ?? 'unknown',
    );
  }

  /// Create wrapper for Map responses
  factory CacheData.fromMap(Map<String, dynamic> data) {
    return CacheData(
      data: data,
      dataType: 'map',
    );
  }

  /// Create wrapper for List responses
  factory CacheData.fromList(List<dynamic> data) {
    return CacheData(
      data: data,
      dataType: 'list',
    );
  }

  /// Create wrapper for nested responses (Map with results/data array)
  factory CacheData.fromNested(Map<String, dynamic> data) {
    return CacheData(
      data: data,
      dataType: 'nested',
    );
  }

  /// Create wrapper for empty responses
  factory CacheData.fromEmpty() {
    return CacheData(
      data: null,
      dataType: 'empty',
    );
  }
}

/// Request deduplication manager
class RequestDeduplicator {
  static final RequestDeduplicator _instance = RequestDeduplicator._internal();
  factory RequestDeduplicator() => _instance;
  RequestDeduplicator._internal();

  final Map<String, Future<dynamic>> _inFlightRequests = {};
  final Map<String, DateTime> _requestTimestamps = {};
  final Set<String> _requestKeys = <String>{};

  /// Get or create a deduplicated request
  Future<T> deduplicate<T>(
    String key,
    Future<T> Function() requestFunction,
  ) async {
    // Check if request is already in flight
    if (_inFlightRequests.containsKey(key)) {
      AppLogger.d('🔄 [RequestDeduplicator] Reusing in-flight request: $key');
      return await _inFlightRequests[key] as T;
    }

    AppLogger.d('🚀 [RequestDeduplicator] Starting new request: $key');
    _requestTimestamps[key] = DateTime.now();
    _requestKeys.add(key);

    try {
      final requestFuture = requestFunction();
      _inFlightRequests[key] = requestFuture;
      
      final result = await requestFuture;
      
      AppLogger.d('✅ [RequestDeduplicator] Request completed: $key (${DateTime.now().difference(_requestTimestamps[key]!).inMilliseconds}ms)');
      return result;
    } catch (e) {
      AppLogger.d('❌ [RequestDeduplicator] Request failed: $key - $e');
      rethrow;
    } finally {
      _inFlightRequests.remove(key);
      _requestTimestamps.remove(key);
    }
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    return {
      'inFlightRequests': _inFlightRequests.length,
      'requests': _requestKeys.toList(),
    };
  }

  /// Clear all in-flight requests (for cleanup)
  void clear() {
    _inFlightRequests.clear();
    _requestTimestamps.clear();
    _requestKeys.clear();
    AppLogger.d('🧹 [RequestDeduplicator] Cleared all requests');
  }
}

/// Dio interceptor for automatic response caching with generic type support
class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager = CacheManager();
  final RequestDeduplicator _deduplicator = RequestDeduplicator();

  CacheInterceptor({
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip caching for certain requests
    if (_shouldSkipCaching(options)) {
      if (_isBlockListEndpoint(options.path)) {
        await _cacheManager.invalidatePattern(ApiConstants.blockList);
      }
      handler.next(options);
      return;
    }

    final cacheKey = _generateCacheKey(options);
    final config = CacheConfigs.getConfigForEndpoint(options.path);

    AppLogger.d('🎯 [CacheInterceptor] 🔍 Checking cache for ${options.path} (key: $cacheKey)');
    
    // Try to get cached data with stale-while-revalidate
    final cacheResult = await _cacheManager.getWithStaleRevalidate<CacheData>(
      cacheKey,
      (data) => _safeCacheDataParse(data, context: '💾 CacheInterceptor.getWithStaleRevalidate') ?? CacheData.fromEmpty(),
      config,
      () => _performRequest(options),
      toJson: (data) => data?.toJson(),
    );

    if (cacheResult.hasData && !cacheResult.isStale) {
      AppLogger.d('🎯 [CacheInterceptor] ✅ Cache hit: ${options.path} (type: ${cacheResult.data!.dataType})');
      
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
      AppLogger.d('🔄 [CacheInterceptor] ⏰ Stale data returned: ${options.path} (type: ${cacheResult.data!.dataType})');
      
      // Return stale data while refreshing in background
      final staleResponse = Response(
        data: _extractOriginalData(cacheResult.data!),
        statusCode: 200,
        requestOptions: options,
        extra: {'fromCache': true, 'isStale': true, 'cacheType': cacheResult.data!.dataType},
      );
      handler.resolve(staleResponse);
      return;
    }

    // No cached data, proceed with request
    handler.next(options);
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

    // Only cache successful GET requests
    if (response.requestOptions.method.toUpperCase() == 'GET' && 
        (response.statusCode ?? 0) >= 200 && 
        (response.statusCode ?? 0) < 300) {
      
      AppLogger.d('💾 [CacheInterceptor] 📝 Caching response: ${response.requestOptions.path}');
      final cacheKey = _generateCacheKey(response.requestOptions);
      final config = CacheConfigs.getConfigForEndpoint(response.requestOptions.path);

      // Create cache data wrapper based on response type
      final cacheData = _createCacheData(response.data);
      AppLogger.d('💾 [CacheInterceptor] 📦 Cache data type: ${cacheData.dataType} for ${response.requestOptions.path}');

      await _cacheManager.put(
        cacheKey,
        cacheData,
        config,
        toJson: (data) => data?.toJson(),
      );

      AppLogger.d('💾 [CacheInterceptor] ✅ Cached response: ${response.requestOptions.path} (${cacheData.dataType})');
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
    if (_shouldReturnStaleOnError(err)) {
      AppLogger.d('🔄 [CacheInterceptor] 🔍 Attempting to return stale data on error: ${err.requestOptions.path}');
      final cacheKey = _generateCacheKey(err.requestOptions);
      final config = CacheConfigs.getConfigForEndpoint(err.requestOptions.path);

      final cached = await _cacheManager.get<CacheData>(
        cacheKey,
        (data) => _safeCacheDataParse(data, context: '🔄 CacheInterceptor.onError') ?? CacheData.fromEmpty(),
        config,
      );

      if (cached != null) {
        AppLogger.d('🔄 [CacheInterceptor] ✅ Returned stale data on error: ${err.requestOptions.path} (type: ${cached.dataType})');
        
        final staleResponse = Response(
          data: _extractOriginalData(cached),
          statusCode: 200,
          requestOptions: err.requestOptions,
          extra: {'fromCache': true, 'isStale': true, 'fromError': true, 'cacheType': cached.dataType},
        );
        handler.resolve(staleResponse);
        return;
      } else {
        AppLogger.d('🚫 [CacheInterceptor] ❌ No stale data available for: ${err.requestOptions.path}');
      }
    }

    handler.next(err);
  }

  /// Performs actual request using a fresh Dio instance with deduplication
  Future<CacheData> _performRequest(RequestOptions options) async {
    final requestKey = _generateCacheKey(options);
    
    return await _deduplicator.deduplicate<CacheData>(
      requestKey,
      () async {
        AppLogger.d('🚀 [CacheInterceptor] 🔍 Performing fresh request: ${options.path}');
        final dio = AppDio.getInstance();
        try {
          final requestOptions = options.copyWith();
          requestOptions.extra = Map<String, dynamic>.from(options.extra);
          requestOptions.extra['skipCache'] = true;

          final response = await dio.fetch(requestOptions);
          
          // Log response data for debugging
          SafeParsingHelpers.logResponseInfo(response.data, '🌐 CacheInterceptor._performRequest');
          
          final cacheData = _createCacheData(response.data);
          AppLogger.d('✅ [CacheInterceptor] 🎉 Fresh request successful: ${options.path} (${cacheData.dataType})');
          return cacheData;
        } catch (e) {
          AppLogger.d('💥 [CacheInterceptor] ❌ _performRequest failed for ${options.path}: $e');
          rethrow;
        }
      },
    );
  }

  /// Generates a unique cache key for the request
  /// CRITICAL: Never include request body in cache key to prevent 405 errors
  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write('${options.method}:${options.path}');
    
    // Add query parameters only (never request body)
    if (options.queryParameters.isNotEmpty) {
      final sortedParams = Map<String, dynamic>.fromEntries(
        options.queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('?${sortedParams.toString()}');
    }
    
    // Add user-specific prefix if available
    if (options.headers.containsKey('Authorization')) {
      // Extract user identifier from token or use generic prefix
      buffer.write('_user');
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
    };

    final method = options.method.toUpperCase();
    final isWriteOperation = method == 'POST' || method == 'PUT' || method == 'DELETE' || method == 'PATCH';

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
      AppLogger.d('📦 [CacheInterceptor] Creating empty cache data');
      return CacheData.fromEmpty();
    }
    
    if (data is Map<String, dynamic>) {
      // Check if it's a nested response (pagination wrapper)
      if (data.containsKey('results') || data.containsKey('data') || data.containsKey('messages')) {
        AppLogger.d('📦 [CacheInterceptor] Creating nested cache data');
        return CacheData.fromNested(data);
      } else {
        AppLogger.d('📦 [CacheInterceptor] Creating map cache data');
        return CacheData.fromMap(data);
      }
    }
    
    if (data is List) {
      AppLogger.d('📦 [CacheInterceptor] Creating list cache data (${data.length} items)');
      return CacheData.fromList(data);
    }
    
    // Try to convert other types to map
    final safeMap = SafeParsingHelpers.safeMapParse(data, context: '🔄 _createCacheData');
    if (safeMap.isNotEmpty) {
      AppLogger.d('📦 [CacheInterceptor] Creating converted map cache data');
      return CacheData.fromMap(safeMap);
    }
    
    // Try to convert to list
    final safeList = SafeParsingHelpers.safeListParse(data, context: '🔄 _createCacheData');
    if (safeList.isNotEmpty) {
      AppLogger.d('📦 [CacheInterceptor] Creating converted list cache data');
      return CacheData.fromList(safeList);
    }
    
    AppLogger.d('📦 [CacheInterceptor] Creating fallback empty cache data for type: ${data.runtimeType}');
    return CacheData.fromEmpty();
  }

  /// Safely parse CacheData from JSON
  CacheData? _safeCacheDataParse(dynamic data, {String? context}) {
    if (data == null) {
      AppLogger.d('⚠️ [CacheInterceptor] ${context ?? 'Unknown'}: data is null');
      return null;
    }
    
    if (data is CacheData) {
      return data;
    }
    
    if (data is Map<String, dynamic>) {
      try {
        return CacheData.fromJson(data);
      } catch (e) {
        AppLogger.d('💥 [CacheInterceptor] ${context ?? 'Unknown'}: failed to parse CacheData: $e');
        return null;
      }
    }
    
    AppLogger.d('⚠️ [CacheInterceptor] ${context ?? 'Unknown'}: data is ${data.runtimeType}, expected CacheData');
    return null;
  }

  /// Extract original data from CacheData wrapper
  dynamic _extractOriginalData(CacheData cacheData) {
    return cacheData.data;
  }

  /// Get deduplication statistics
  Map<String, dynamic> getDeduplicationStats() {
    return _deduplicator.getStats();
  }

  /// Clear all in-flight requests
  void clearInFlightRequests() {
    _deduplicator.clear();
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

/// Cache invalidation helper
class CacheInvalidationHelper {
  final CacheManager _cacheManager = CacheManager();

  /// Invalidate cache entries based on action
  Future<void> invalidateOnAction(CacheAction action, {String? resourceId}) async {
    switch (action.type) {
      case CacheActionType.post:
        await _invalidateOnPost(resourceId);
        break;
      case CacheActionType.like:
        await _invalidateOnLike(resourceId);
        break;
      case CacheActionType.follow:
        await _invalidateOnFollow(resourceId);
        break;
      case CacheActionType.comment:
        await _invalidateOnComment(resourceId);
        break;
      case CacheActionType.message:
        await _invalidateOnMessage(resourceId);
        break;
      case CacheActionType.profileUpdate:
        await _invalidateOnProfileUpdate(resourceId);
        break;
      case CacheActionType.storyCreate:
        await _invalidateOnStoryCreate(resourceId);
        break;
      case CacheActionType.highlightUpdate:
        await _invalidateOnHighlightUpdate(resourceId);
        break;
    }
  }

  Future<void> _invalidateOnPost(String? postId) async {
    // Invalidate feed cache
    await _cacheManager.invalidatePattern('feed');
    await _cacheManager.invalidatePattern('posts');
    
    // Invalidate user profile
    await _cacheManager.invalidatePattern('profile');
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for new post: $postId');
  }

  Future<void> _invalidateOnLike(String? postId) async {
    // Invalidate feed and post details
    await _cacheManager.invalidatePattern('feed');
    await _cacheManager.invalidatePattern('posts/$postId');
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for like: $postId');
  }

  Future<void> _invalidateOnFollow(String? userId) async {
    // Invalidate profile caches
    await _cacheManager.invalidatePattern('profile');
    await _cacheManager.invalidatePattern('user/profile');
    if (userId != null && userId.isNotEmpty) {
      await _cacheManager.invalidatePattern(userId);
    }
    await _cacheManager.invalidatePattern(ApiConstants.getPost);

    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for follow: $userId');
  }

  Future<void> _invalidateOnComment(String? postId) async {
    // Invalidate post details and feed
    await _cacheManager.invalidatePattern('posts/$postId');
    await _cacheManager.invalidatePattern('feed');
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for comment: $postId');
  }

  Future<void> _invalidateOnMessage(String? conversationId) async {
    // Invalidate conversation caches
    await _cacheManager.invalidatePattern('conversations');
    if (conversationId != null) {
      await _cacheManager.invalidatePattern('conversations/$conversationId');
    }
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for message: $conversationId');
  }

  Future<void> _invalidateOnProfileUpdate(String? userId) async {
    // Invalidate all profile-related caches
    await _cacheManager.invalidatePattern('profile');
    await _cacheManager.invalidatePattern('user/$userId');
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for profile update: $userId');
  }

  Future<void> _invalidateOnStoryCreate(String? userId) async {
    // Invalidate story caches
    await _cacheManager.invalidatePattern('stories');
    await _cacheManager.invalidatePattern('profile');
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for story create: $userId');
  }

  Future<void> _invalidateOnHighlightUpdate(String? highlightId) async {
    // Invalidate highlight caches
    await _cacheManager.invalidatePattern('highlights');
    if (highlightId != null) {
      await _cacheManager.invalidatePattern('highlights/$highlightId');
    }
    
    AppLogger.d('🗑️ [CacheInvalidation] Invalidated caches for highlight update: $highlightId');
  }
}

/// Cache action types for invalidation
enum CacheActionType {
  post,
  like,
  follow,
  comment,
  message,
  profileUpdate,
  storyCreate,
  highlightUpdate,
}

/// Cache action for invalidation
class CacheAction {
  final CacheActionType type;
  final String? resourceId;

  CacheAction({
    required this.type,
    this.resourceId,
  });
}
