import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/token_refresh_service.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/auth/token_storage.dart';

/// Production-level Dio interceptor for automatic token refresh and retry
class RefreshTokenInterceptor extends Interceptor {
  final TokenRefreshService _refreshService = TokenRefreshService();
  final Dio _dio;

  /// Set of request paths that should not trigger token refresh
  final Set<String> _skipRefreshPaths = {
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
    '/auth/logout',
    '/auth/forgot-password',
    '/auth/reset-password',
  };

  RefreshTokenInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for certain endpoints
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    // Add authorization header if not present
    await _addAuthHeaderIfNeeded(options);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 errors
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Skip refresh for certain paths
    if (_shouldSkipRefresh(err.requestOptions)) {
      handler.next(err);
      return;
    }

    // Check if this request was already retried
    if (err.requestOptions.extra['retry'] == true) {
      debugPrint('❌ [RefreshInterceptor] Request already retried, failing');
      handler.next(err);
      return;
    }

    debugPrint(
      '🔄 [RefreshInterceptor] 401 detected, attempting token refresh',
    );

    try {
      // Attempt to refresh tokens
      final newTokens = await _refreshService.refreshTokens();

      if (newTokens != null) {
        debugPrint(
          '✅ [RefreshInterceptor] Token refresh successful, retrying request',
        );

        // Clone the request with new auth header
        final retryOptions = _cloneRequestOptions(err.requestOptions);
        retryOptions.headers['Authorization'] =
            'Bearer ${newTokens['accessToken']}';
        retryOptions.extra['retry'] = true;

        // Retry the request
        try {
          final response = await _dio.fetch(retryOptions);
          handler.resolve(response);
          return;
        } catch (retryError) {
          debugPrint('❌ [RefreshInterceptor] Retry failed: $retryError');
          // If retry fails with another 401, trigger logout
          if (retryError is DioException &&
              retryError.response?.statusCode == 401) {
            await _handleAuthFailure();
          }
          if (retryError is DioException) {
            handler.next(retryError);
          } else {
            handler.next(err);
          }
          return;
        }
      } else {
        debugPrint(
          '❌ [RefreshInterceptor] Token refresh failed, triggering logout',
        );
        await _handleAuthFailure();
        handler.next(err);
        return;
      }
    } catch (refreshError) {
      debugPrint('❌ [RefreshInterceptor] Refresh process error: $refreshError');
      await _handleAuthFailure();
      handler.next(err);
    }
  }

  /// Adds authorization header if not present and token exists
  Future<void> _addAuthHeaderIfNeeded(RequestOptions options) async {
    final hasAuthHeader =
        options.headers.containsKey('Authorization') &&
        (options.headers['Authorization']?.toString().trim().isNotEmpty ??
            false);

    if (!hasAuthHeader) {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
  }

  /// Checks if the request path should skip token refresh
  bool _shouldSkipRefresh(RequestOptions options) {
    final path = options.path;
    return _skipRefreshPaths.any((skipPath) => path.contains(skipPath));
  }

  /// Clones request options for retry
  RequestOptions _cloneRequestOptions(RequestOptions original) {
    return RequestOptions(
      method: original.method,
      path: original.path,
      baseUrl: original.baseUrl,
      queryParameters: original.queryParameters,
      data: original.data,
      headers: Map<String, dynamic>.from(original.headers),
      contentType: original.contentType,
      responseType: original.responseType,
      receiveTimeout: original.receiveTimeout,
      sendTimeout: original.sendTimeout,
      connectTimeout: original.connectTimeout,
      extra: Map<String, dynamic>.from(original.extra),
      cancelToken: original.cancelToken,
    );
  }

  /// Handles authentication failure by clearing tokens and navigating to login
  Future<void> _handleAuthFailure() async {
    debugPrint(
      '🚨 [RefreshInterceptor] Handling auth failure - clearing tokens and logging out',
    );

    try {
      // Use the auth state manager to handle logout
      await AuthStateManager().onAuthFailure();
    } catch (e) {
      debugPrint(
        '❌ [RefreshInterceptor] Error during auth failure handling: $e',
      );
    }
  }
}
