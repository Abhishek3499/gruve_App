import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/network/api_logger.dart';
import 'package:gruve_app/core/network/app_dio.dart';

/// Lightweight Dio client for auth endpoints — no cache, retry, or dedup overhead.
class AuthDio {
  static Dio? _instance;

  static Dio getInstance() {
    _instance ??= _build();
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }

  static Dio _build() {
    var baseUrl = EnvironmentConfig.baseUrl.trim();
    if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    // Logger runs first (index 0) so it only observes the final outcome of a
    // request — including one recovered by RetryInterceptor below — mirroring
    // the interceptor ordering documented in AppDio._buildDio().
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            ApiLogger.logResponse(response);
            handler.next(response);
          },
          onError: (error, handler) {
            ApiLogger.logError(error);
            handler.next(error);
          },
        ),
      );
    }

    // Reuse existing RetryInterceptor configured to:
    // - Retry ONLY 1 time
    // - Retry ONLY on 502, 503, 504 (and connection/timeout/socket exceptions check inside)
    // - Never retry on 400, 401, 403, 404, 409, 422, etc.
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        maxRetries: 1,
        retriableStatuses: const {502, 503, 504},
      ),
    );

    return dio;
  }
}
