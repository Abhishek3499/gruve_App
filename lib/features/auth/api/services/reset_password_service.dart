import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';
import '../models/reset_password_model.dart';

class ResetPasswordService {
  final Dio _dio = AppDio.create(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  Future<ResetPasswordResponse> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      const endpoint = "auth/password/reset/confirm/";
      final requestData = {
        "reset_token": token,
        "password": password,
      };

      AuthApiLogger.request(
        'ResetPassword',
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: requestData,
      );

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('ResetPassword', response);

      return ResetPasswordResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error('ResetPassword', e);

      return ResetPasswordResponse(
        message: AuthApiException.extractMessage(e, fallback: 'Server error'),
        success: false,
      );
    } catch (e) {
      debugPrint("Reset password failed: $e");

      return ResetPasswordResponse(
        message: "Something went wrong",
        success: false,
      );
    }
  }
}
