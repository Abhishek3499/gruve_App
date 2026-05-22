import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';

class ApiClient {
  ApiClient() : _dio = AppDio.create();

  final Dio _dio;

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _dio.get<dynamic>(endpoint);
      return response.data;
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[ApiClient] GET $endpoint failed: '
          'status=${error.response?.statusCode} type=${error.type}',
        );
      }
      rethrow;
    }
  }
}
