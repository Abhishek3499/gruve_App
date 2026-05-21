import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthApiLogger {
  const AuthApiLogger._();

  static void request(
    String label, {
    required Dio dio,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) {
    if (!kDebugMode) return;

    debugPrint('[$label] $method ${dio.options.baseUrl}$endpoint');
    if (body != null) {
      debugPrint('[$label] bodyKeys=${body.keys.toList()}');
    }
  }

  static void response(String label, Response response) {
    if (!kDebugMode) return;

    debugPrint('[$label] status=${response.statusCode}');
  }

  static void error(String label, DioException error) {
    if (!kDebugMode) return;

    debugPrint(
      '[$label] error status=${error.response?.statusCode} type=${error.type}',
    );
  }
}
