import 'package:dio/dio.dart';
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
  }) async {
    try {
      final body = {
        type: identifier, // 🔥 dynamic key (email/phone)
        "otp": otp,
      };

      final response = await dio.post("auth/verify-otp/", data: body);

      final result = VerifyOtpResponse.fromJson(response.data);

      // 🔥 SAME LOGIC AS SIGNUP
      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      throw e.response?.data["message"] ?? "Something went wrong";
    }
  }
}
