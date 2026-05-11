import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/core/network/refresh_token_interceptor.dart';
import 'package:gruve_app/core/network/pending_request_queue.dart';
import 'package:gruve_app/core/network/token_refresh_service.dart';

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

    // Add refresh token interceptor
    dio.interceptors.add(RefreshTokenInterceptor(dio));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
