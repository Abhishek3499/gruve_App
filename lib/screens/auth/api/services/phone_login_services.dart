import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/phone_login_model.dart';

class PhoneSiginServices {
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
        'phone_number',
        'phone',
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

  Future<PhoneloginResponse> signIn({required String phone_number}) async {
    try {
      final response = await _dio.post(
        "auth/phone-login/",
        data: {
          "phone_number": phone_number,
        },
      );

      debugPrint("PHONE LOGIN RESPONSE: ${response.data}");

      return PhoneloginResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("API ERROR: ${e.response?.data}");
      throw _extractErrorMessage(e);
    }
  }
}
