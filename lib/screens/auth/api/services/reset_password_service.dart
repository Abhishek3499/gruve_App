import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/reset_password_model.dart';

class ResetPasswordService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));

  Future<ResetPasswordResponse> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "auth/password/reset/confirm/",
        data: {"reset_token": token, "password": password},
      );

      return ResetPasswordResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        return ResetPasswordResponse(
          message: e.response?.data['message'] ?? "Server error",
          success: false,
        );
      }
      throw Exception("Reset password failed");
    }
  }
}
