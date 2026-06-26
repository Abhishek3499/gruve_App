import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/core/network/refresh_token_interceptor.dart';
import 'package:gruve_app/core/network/pending_request_queue.dart';
import 'package:gruve_app/core/network/token_refresh_service.dart';
import 'package:gruve_app/core/network/request_deduplication_manager.dart';
import 'package:gruve_app/core/cache/cache_interceptor.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/monitoring/network_monitor.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class AppDio {
  static CancelToken? _logoutCancelToken;
  static PendingRequestQueue? _pendingQueue;
  static Dio? _instance;

  static CancelToken get _cancelToken => _logoutCancelToken ??= CancelToken();

  static PendingRequestQueue get _queue =>
      _pendingQueue ??= PendingRequestQueue(TokenRefreshService());

  static void cancelAllRequests([String? reason]) {
    if (_logoutCancelToken != null && !_logoutCancelToken!.isCancelled) {
      _logoutCancelToken!.cancel(reason ?? 'Logout request cancellation');
    }
    _logoutCancelToken = CancelToken();

    // Also cancel pending queued requests
    _queue.cancelAll(reason);

    // Cancel all in-flight deduplicated requests
    RequestDeduplicationManager().cancelAll(reason);

    // Clear cache on logout
    CacheManager().clear();

    // Reset singleton instance on logout
    _instance = null;
  }

  static Dio getInstance() {
    _instance ??= _buildDio();
    return _instance!;
  }

  static Dio _buildDio() {
    var baseUrl = EnvironmentConfig.baseUrl.trim();
    if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 45), // Increased for slow networks
        receiveTimeout: const Duration(minutes: 3), // Increased for large videos
        sendTimeout: const Duration(minutes: 2), // Keep send timeout for large uploads
      ),
    );

    // Auth/metrics must run before cache and deduplication so the request key
    // and cached response both represent the final authenticated request.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.extra['request_start_time'] = DateTime.now();

          final hasAuthorizationHeader =
              options.headers.containsKey('Authorization') &&
              (options.headers['Authorization']?.toString().trim().isNotEmpty ??
                  false);
          final isExternal = (options.path.startsWith('http://') || options.path.startsWith('https://')) &&
              !options.path.startsWith(baseUrl);
          final skipAuth =
              options.extra['skipAuth'] == true ||
              isExternal ||
              AuthEndpointPaths.shouldSkipAuth(options.path);

          if (!skipAuth && !hasAuthorizationHeader) {
            final token = await TokenStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          options.cancelToken = options.cancelToken ?? _cancelToken;
          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime =
              response.requestOptions.extra['request_start_time'] as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            NetworkMonitor().logApiCall(
              method: response.requestOptions.method,
              endpoint: response.requestOptions.path,
              duration: duration,
              statusCode: response.statusCode ?? 0,
            );
          }

          // 📊 Log response size in debug mode to track GZIP decompression/payloads
          if (kDebugMode) {
            final contentLength = response.headers.value(Headers.contentLengthHeader) ??
                                  response.headers.value('content-length');
            int sizeInBytes = 0;
            if (contentLength != null) {
              sizeInBytes = int.tryParse(contentLength) ?? 0;
            } else if (response.data != null) {
              try {
                sizeInBytes = response.data.toString().length;
              } catch (_) {}
            }
            AppLogger.d('📊 [Response Size] ${response.requestOptions.method} ${response.requestOptions.path} | Size: ${(sizeInBytes / 1024).toStringAsFixed(2)} KB ($sizeInBytes bytes)');
          }

          handler.next(response);
        },
        onError: (error, handler) {
          final startTime =
              error.requestOptions.extra['request_start_time'] as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            NetworkMonitor().logApiCall(
              method: error.requestOptions.method,
              endpoint: error.requestOptions.path,
              duration: duration,
              statusCode: error.response?.statusCode ?? 0,
              error: error.message,
            );
          }
          handler.next(error);
        },
      ),
    );

    // Retry interceptor to handle failed requests up to 2 times
    dio.interceptors.add(RetryInterceptor(dio: dio));

    // Refresh runs after auth attaches the current token.
    dio.interceptors.add(RefreshTokenInterceptor(dio));

    // Cache before deduplication gives stale data a chance to answer without
    // creating an in-flight network request.
    dio.interceptors.add(CacheInterceptor());

    // Coalesce duplicate in-flight GET requests.
    dio.interceptors.add(RequestDeduplicationInterceptor());

    return dio;
  }
}

/// 🚀 Dio Interceptor that retries failed requests up to 2 times with a 1s delay
class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    
    // Prevent infinite retry loops by checking current retry count
    final attempts = requestOptions.extra['retry_attempts'] as int? ?? 0;

    // Retry only on timeouts or connection/network errors, or specific transient server errors
    final isTransient = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            {408, 429, 502, 503, 504}.contains(err.response!.statusCode));

    if (isTransient && attempts < 2) {
      requestOptions.extra['retry_attempts'] = attempts + 1;
      
      AppLogger.d('🔄 [RetryInterceptor] Failed with ${err.type} (Status: ${err.response?.statusCode}). Retrying ${requestOptions.method} ${requestOptions.path} (Attempt ${attempts + 1}/2) in 1s...');
      
      // Delay 1 second before retry
      await Future<void>.delayed(const Duration(seconds: 1));
      
      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          // Pass the new DioException down the chain
          return super.onError(e, handler);
        }
        return super.onError(DioException(requestOptions: requestOptions, error: e), handler);
      }
    }

    return super.onError(err, handler);
  }
}
