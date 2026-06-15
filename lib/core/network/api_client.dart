import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ApiClient {
  ApiClient() : _dio = AppDio.getInstance();

  final Dio _dio;

  Future<dynamic> get(String endpoint, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<dynamic>(endpoint, cancelToken: cancelToken);
      return response.data;
    } on DioException catch (error) {
      AppLogger.d(
          '[ApiClient] GET $endpoint failed: '
          'status=${error.response?.statusCode} type=${error.type}',
        );
      
      rethrow;
    }
  }
}
