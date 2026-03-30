import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/verify_otp_response.dart';

class VerifyOtpService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL']!, // 🔥
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  Future<VerifyOtpResponse> verifyOtp({
    required String identifier,
    required String type, // "email" OR "phone"
    required String otp,
    bool isLogin = false, // ✅ NEW
  }) async {
    try {
      Map<String, dynamic> body;
      String endpoint;

      // ✅ Decide endpoint
      if (isLogin) {
        endpoint = "auth/verify-phone-login-otp/";
      } else {
        endpoint = "auth/verify-otp/";
      }

      // ✅ Body
      if (type == "phone") {
        body = {"identifier": identifier, "otp": otp};
      } else {
        body = {"identifier": identifier, "otp": otp};
      }

      // 🔥 DEBUG
      debugPrint("📤 ENDPOINT: $endpoint");
      debugPrint("📤 BODY: $body");

      final response = await dio.post(endpoint, data: body);

      debugPrint("📥 RESPONSE: ${response.data}");

      final result = VerifyOtpResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      debugPrint("❌ ERROR: ${e.response?.data}");
      throw e.response?.data["message"] ?? "Something went wrong";
    }
  }
}
