import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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

    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.extra['request_start_time'] = DateTime.now();
            handler.next(options);
          },
          onResponse: (response, handler) {
            final startTime =
                response.requestOptions.extra['request_start_time'] as DateTime?;
            if (startTime != null) {
              final ms = DateTime.now().difference(startTime).inMilliseconds;
              AppLogger.d(
                '[AuthDio] ${response.requestOptions.method} '
                '${response.requestOptions.path} ${response.statusCode} (${ms}ms)',
              );
            }
            handler.next(response);
          },
          onError: (error, handler) {
            final startTime =
                error.requestOptions.extra['request_start_time'] as DateTime?;
            if (startTime != null) {
              final ms = DateTime.now().difference(startTime).inMilliseconds;
              AppLogger.d(
                '[AuthDio] ${error.requestOptions.method} '
                '${error.requestOptions.path} failed (${ms}ms)',
              );
            }
            handler.next(error);
          },
        ),
      );
    }

    return dio;
  }
}
