import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:gruve_app/core/network/app_dio.dart';
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

      debugPrint("=== RESET PASSWORD REQUEST ===");
      debugPrint("URL: ${_dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: ${_dio.options.headers}");
      debugPrint("BODY: $requestData");

      final response = await _dio.post(endpoint, data: requestData);

      debugPrint("=== RESET PASSWORD RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");

      return ResetPasswordResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("=== RESET PASSWORD DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");

      return ResetPasswordResponse(
        message: e.response?.data?['message'] ?? "Server error",
        success: false,
      );
    } catch (e) {
      debugPrint("=== RESET PASSWORD UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");

      return ResetPasswordResponse(
        message: "Something went wrong",
        success: false,
      );
    }
  }
}
