import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/login_model.dart';

class EmailSignInService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));

  String _extractErrorMessage(Object error) {
    if (error is! DioException) {
      return "Something went wrong";
    }

    final data = error.response?.data;

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map<String, dynamic>) {
      for (final key in [
        'message',
        'detail',
        'email',
        'password',
        'non_field_errors',
      ]) {
        final value = data[key];

        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }

        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        }
      }
    }

    return "Something went wrong";
  }

  Future<EmailSignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "auth/login/",
        data: {
          "email": email,
          "password": password,
        },
      );

      debugPrint("EMAIL LOGIN RESPONSE: ${response.data}");

      return EmailSignInResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("API ERROR: ${e.response?.data}");
      throw _extractErrorMessage(e);
    }
  }
}
