import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/core/auth_api_exception.dart';
import 'package:gruve_app/screens/auth/core/auth_api_logger.dart';

class ForgotPasswordService {
  final Dio _dio = AppDio.create();
  Future<String> sendResetLink({required String email}) async {
    try {
      const endpoint = 'auth/forgot-password/';
      final requestData = {"email": email};
      
      AuthApiLogger.request(
        'ForgotPassword',
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: requestData,
      );

      final response = await _dio.post(endpoint, data: requestData);

      AuthApiLogger.response('ForgotPassword', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data["message"] ?? "Reset link sent";
      } else {
        throw Exception("Failed to send reset link");
      }
    } on DioException catch (e) {
      AuthApiLogger.error('ForgotPassword', e);

      throw Exception(AuthApiException.extractMessage(e));
    } catch (e) {
      debugPrint("Forgot password failed: $e");
      rethrow;
    }
  }
}
