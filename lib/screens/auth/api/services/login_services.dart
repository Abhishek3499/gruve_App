import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/login_model.dart';

class EmailSignInService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: (dotenv.env['BASE_URL'] ?? '').trim(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  Future<EmailSignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw "BASE_URL is missing in .env";
    }

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

  String _extractErrorMessage(DioException e) {
    final responseData = e.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData["message"];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final error = responseData["error"];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      final errors = responseData["errors"];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first;
            }
          }

          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timed out. Please check your internet and try again.";
      case DioExceptionType.connectionError:
        return "Unable to connect. Please check your internet connection.";
      default:
        return "Unable to sign in right now. Please try again.";
    }
  }
}
