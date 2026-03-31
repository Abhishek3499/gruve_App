import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForgotPasswordService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));
  Future<String> sendResetLink({required String email}) async {
    try {
      final response = await _dio.post(
        'auth/forgot-password/',
        data: {"email": email},
      );

      debugPrint("📤 REQUEST EMAIL: $email");
      debugPrint("📥 STATUS CODE: ${response.statusCode}");
      debugPrint("📥 RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data["message"] ?? "Reset link sent";
      } else {
        throw Exception("Failed to send reset link");
      }
    } on DioException catch (e) {
      debugPrint("❌ ERROR STATUS: ${e.response?.statusCode}");
      debugPrint("❌ ERROR DATA: ${e.response?.data}");
      debugPrint("❌ ERROR MESSAGE: ${e.message}");

      throw Exception(e.response?.data["message"] ?? "Something went wrong");
    }
  }
}
