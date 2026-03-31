import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/phone_login_model.dart';

class PhoneSiginServices {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));
  Future<PhoneloginResponse> signIn({required String phone_number}) async {
    try {
      final response = await _dio.post(
        "auth/phone-login/",
        data: {
          "phone_number": phone_number, // 🔥 email OR phone
        },
      );

      debugPrint("🔥 EMAIL LOGIN RESPONSE: ${response.data}");

      return PhoneloginResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("❌ API ERROR: ${e.response?.data}");

      throw e.response?.data["message"] ?? "Something went wrong";
    }
  }
}
