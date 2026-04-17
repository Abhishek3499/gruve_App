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
    required String email,
    required String phone_number,
    required String type,
    required String otp,
    bool isLogin = false,
    bool isForgot = false, // ✅ ADD THIS
  }) async {
    try {
      debugPrint("=== VERIFY OTP REQUEST ===");
      debugPrint("isForgot: $isForgot");
      debugPrint("isLogin: $isLogin");
      debugPrint("type: $type");
      debugPrint("email: $email");
      debugPrint("phone: $phone_number");

      Map<String, dynamic> body;
      String endpoint;

      // Decide endpoint
      if (isForgot) {
        endpoint = "auth/password-reset/verify-otp/";
        body = {"email": email, "otp": otp};
      } else if (isLogin) {
        endpoint = "auth/verify-phone-login-otp/";
        body = {"phone_number": phone_number, "otp": otp};
      } else {
        endpoint = "auth/verify-otp/";

        // Signup (email OR phone)
        if (type == "phone") {
          body = {"identifier": identifier, "otp": otp};
        } else {
          body = {"identifier": identifier, "otp": otp};
        }
      }

      debugPrint("=== VERIFY OTP REQUEST DETAILS ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: ${dio.options.headers}");
      debugPrint("BODY: $body");

      final response = await dio.post(endpoint, data: body);

      debugPrint("=== VERIFY OTP RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");

      final result = VerifyOtpResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      debugPrint("=== VERIFY OTP DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      throw e.response?.data["message"] ?? "Something went wrong";
    } catch (e) {
      debugPrint("=== VERIFY OTP UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      rethrow;
    }
  }
}
