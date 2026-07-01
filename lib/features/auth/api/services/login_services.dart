import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';

import '../models/login_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class EmailSignInService {
  final Dio _dio = AuthDio.getInstance();

  Future<EmailSignInResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    return _login(
      identifier: identifier,
      body: {"identifier": identifier, "password": password},
      logLabel: 'EmailLogin',
      fallbackMessage: 'Please enter the correct password.',
    );
  }

  Future<EmailSignInResponse> requestLoginOtp({
    required String identifier,
  }) async {
    return _login(
      identifier: identifier,
      body: {"identifier": identifier},
      logLabel: 'PhoneLoginOtp',
      fallbackMessage: 'Please enter a valid phone number.',
    );
  }

  Future<EmailSignInResponse> _login({
    required String identifier,
    required Map<String, dynamic> body,
    required String logLabel,
    required String fallbackMessage,
  }) async {
    if (_dio.options.baseUrl.trim().isEmpty) {
      throw "BASE_URL is missing in .env";
    }

    try {
      const endpoint = "auth/login/";

      AuthApiLogger.request(
        logLabel,
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: body,
      );

      final response = await _dio.post(
        endpoint,
        data: body,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response(logLabel, response);

      return EmailSignInResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error(logLabel, e);
      throw AuthApiException.extractMessage(
        e,
        fallback: fallbackMessage,
      );
    } catch (e) {
      AppLogger.d("$logLabel failed: $e");
      rethrow;
    }
  }
}
