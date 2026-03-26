import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/login_model.dart';

class EmailSignInService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));
  Future<EmailSignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "auth/login/",
        data: {"email": email, "password": password},
      );

      debugPrint("🔥 EMAIL LOGIN RESPONSE: ${response.data}");

      return EmailSignInResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("❌ API ERROR: ${e.response?.data}");

      throw e.response?.data["message"] ?? "Something went wrong";
    }
  }
}
