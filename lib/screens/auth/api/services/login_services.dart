import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';

import '../models/login_model.dart';

class EmailSignInService {
  final Dio _dio = AppDio.create();

  Future<EmailSignInResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    if (_dio.options.baseUrl.trim().isEmpty) {
      throw "BASE_URL is missing in .env";
    }

    try {
      const endpoint = "auth/login/";
      final requestData = {"identifier": identifier, "password": password};
      
      debugPrint("=== EMAIL LOGIN REQUEST ===");
      debugPrint("URL: ${_dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("BODY KEYS: ${requestData.keys.toList()}");
      
      final response = await _dio.post(endpoint, data: requestData);

      debugPrint("=== EMAIL LOGIN RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE RECEIVED");

      return EmailSignInResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("=== EMAIL LOGIN ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA TYPE: ${e.response?.data.runtimeType}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      throw _extractErrorMessage(e);
    } catch (e) {
      debugPrint("=== EMAIL LOGIN UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      rethrow;
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
