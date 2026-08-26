import 'package:dio/dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class AuthApiLogger {
  const AuthApiLogger._();

  static void request(
    String label, {
    required Dio dio,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) {
    AppLogger.d('[$label] $method ${dio.options.baseUrl}$endpoint');
    if (body != null) {
      AppLogger.d('[$label] bodyKeys=${body.keys.toList()}');
    }
  }

  static void response(String label, Response response) {
    AppLogger.d('[$label] status=${response.statusCode}');
  }

  static void error(String label, DioException error) {
    AppLogger.d(
      '[$label] error status=${error.response?.statusCode} type=${error.type}',
    );
  }
}
