import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';

class ForgotPasswordService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is String && data.trim().isNotEmpty) {
      return SignupValidator.normalizeEmailNotFoundMessage(data.trim());
    }

    if (data is Map<String, dynamic>) {
      for (final key in ['message', 'detail', 'email', 'non_field_errors']) {
        final value = data[key];

        if (value is String && value.trim().isNotEmpty) {
          return SignupValidator.normalizeEmailNotFoundMessage(value.trim());
        }

        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return SignupValidator.normalizeEmailNotFoundMessage(first.trim());
          }
        }
      }
    }

    return "Something went wrong";
  }

  Future<String> sendResetLink({required String email}) async {
    try {
      final response = await _dio.post(
        'auth/forgot-password/',
        data: {"email": email},
      );

      debugPrint("REQUEST EMAIL: $email");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data["message"] ?? "Reset link sent";
      }

      throw Exception("Failed to send reset link");
    } on DioException catch (error) {
      debugPrint("ERROR STATUS: ${error.response?.statusCode}");
      debugPrint("ERROR DATA: ${error.response?.data}");
      debugPrint("ERROR MESSAGE: ${error.message}");

      throw Exception(_extractErrorMessage(error));
    }
  }
}
