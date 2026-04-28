import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';

class ForgotPasswordService {
  final Dio _dio = AppDio.create();
  Future<String> sendResetLink({required String email}) async {
    try {
      const endpoint = 'auth/forgot-password/';
      final requestData = {"email": email};
      
      debugPrint("=== FORGOT PASSWORD REQUEST ===");
      debugPrint("URL: ${_dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: ${_dio.options.headers}");
      debugPrint("BODY: $requestData");

      final response = await _dio.post(endpoint, data: requestData);

      debugPrint("=== FORGOT PASSWORD RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data["message"] ?? "Reset link sent";
      } else {
        throw Exception("Failed to send reset link");
      }
    } on DioException catch (e) {
      debugPrint("=== FORGOT PASSWORD DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");

      throw Exception(e.response?.data["message"] ?? "Something went wrong");
    } catch (e) {
      debugPrint("=== FORGOT PASSWORD UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      rethrow;
    }
  }
}
