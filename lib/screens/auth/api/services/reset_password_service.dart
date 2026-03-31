import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/reset_password_model.dart';

class ResetPasswordService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL']!,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<ResetPasswordResponse> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      debugPrint("📤 RESET PASSWORD REQUEST");
      debugPrint("🔐 TOKEN: $token");
      debugPrint("🔑 PASSWORD: $password");

      final response = await _dio.post(
        "auth/password/reset/confirm/",
        data: {
          "reset_token": token, // ✅ CORRECT KEY
          "password": password,
        },
      );

      debugPrint("📥 STATUS CODE: ${response.statusCode}");
      debugPrint("📥 RESPONSE: ${response.data}");

      return ResetPasswordResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("❌ ERROR STATUS: ${e.response?.statusCode}");
      debugPrint("❌ ERROR DATA: ${e.response?.data}");
      debugPrint("❌ ERROR MESSAGE: ${e.message}");

      return ResetPasswordResponse(
        message: e.response?.data?['message'] ?? "Server error",
        success: false,
      );
    } catch (e) {
      debugPrint("❌ UNKNOWN ERROR: $e");

      return ResetPasswordResponse(
        message: "Something went wrong",
        success: false,
      );
    }
  }
}
