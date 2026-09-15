import 'package:dio/dio.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';

class AuthApiLogger {
  const AuthApiLogger._();

  static void request(
    String label, {
    required Dio dio,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) {
    authLogger.d('[$label] $method ${dio.options.baseUrl}$endpoint');
    if (body != null) {
      authLogger.d('[$label] bodyKeys=${body.keys.toList()}');
    }
  }

  static void response(String label, Response response) {
    authLogger.d('[$label] status=${response.statusCode}');
  }

  static void error(String label, DioException error) {
    authLogger.d(
      '[$label] error status=${error.response?.statusCode} type=${error.type}',
    );
  }
}
