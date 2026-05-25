import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';

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
      
      AuthApiLogger.request(
        'EmailLogin',
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: requestData,
      );
      
      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('EmailLogin', response);

      return EmailSignInResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error('EmailLogin', e);
      throw AuthApiException.extractMessage(
        e,
        fallback: 'Unable to sign in right now. Please try again.',
      );
    } catch (e) {
      debugPrint("Email login failed: $e");
      rethrow;
    }
  }
}
