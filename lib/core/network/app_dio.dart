import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/core/network/refresh_token_interceptor.dart';
import 'package:gruve_app/core/network/pending_request_queue.dart';
import 'package:gruve_app/core/network/token_refresh_service.dart';
import 'package:gruve_app/core/network/request_deduplication_manager.dart';
import 'package:gruve_app/core/cache/cache_interceptor.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/monitoring/network_monitor.dart';

class AppDio {
  static CancelToken? _logoutCancelToken;
  static PendingRequestQueue? _pendingQueue;

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
  }

  static Dio create({
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
    Duration sendTimeout = const Duration(seconds: 20),
  }) {
    var baseUrl = (dotenv.env['BASE_URL'] ?? '').trim();
    if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
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
          final skipAuth = options.extra['skipAuth'] == true;

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
          final startTime = response.requestOptions.extra['request_start_time'] as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            NetworkMonitor().logApiCall(
              method: response.requestOptions.method,
              endpoint: response.requestOptions.path,
              duration: duration,
              statusCode: response.statusCode ?? 0,
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          final startTime = error.requestOptions.extra['request_start_time'] as DateTime?;
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
