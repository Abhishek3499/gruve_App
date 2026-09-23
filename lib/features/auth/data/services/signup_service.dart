import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/dto/signup_request.dart';
import 'package:gruve_app/features/auth/data/dto/signup_response.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';

class SignupService {
  final Dio dio = AuthDio.getInstance();

  Future<SignupResponse> signup(SignupRequest request) async {
    const endpoint = ApiConstants.signup;
    final payload = request.toJson();

    try {
      return await _postSignup(endpoint, payload, logLabel: 'Signup');
    } on AuthApiException {
      rethrow;
    } on DioException catch (e) {
      if (_shouldRetry(e)) {
        authLogger.d('Signup retry attempt');
        try {
          return await _postSignup(endpoint, payload, logLabel: 'SignupRetry');
        } on AuthApiException {
          rethrow;
        } on DioException catch (retryError) {
          throw AuthApiException.fromDio(
            retryError,
            fallback: 'Unable to reach server right now. Please try again.',
          );
        }
      }

      throw AuthApiException.fromDio(
        e,
        fallback: 'Unable to reach server right now. Please try again.',
      );
    } on SocketException catch (e) {
      authLogger.d('Signup SocketException: $e');
      throw const AuthApiException(
        'No internet connection. Please check your network and try again.',
        type: 'SocketException',
      );
    } on TimeoutException catch (e) {
      authLogger.d('Signup TimeoutException: $e');
      throw const AuthApiException(
        'Request timed out. Please check your internet and try again.',
        type: 'TimeoutException',
      );
    } on FormatException catch (e) {
      authLogger.d('Signup FormatException: $e');
      throw const AuthApiException(
        'Server returned an invalid response format.',
        type: 'FormatException',
      );
    } catch (e) {
      authLogger.d('Signup failed: $e');
      throw AuthApiException(
        'Something went wrong. Please try again.',
        type: 'unknown',
      );
    }
  }

  Future<SignupResponse> _postSignup(
    String endpoint,
    Map<String, dynamic> payload, {
    required String logLabel,
  }) async {
    final response = await dio.post(
      endpoint,
      data: payload,
      options: AuthEndpointPaths.skipAuthOptions(),
    );

    final result = SignupResponse.fromJson(response.data);
    if (result.success == true) {
      return result;
    }
    throw AuthApiException(
      result.message.isNotEmpty
          ? result.message
          : 'Signup failed. Please try again.',
      statusCode: response.statusCode,
    );
  }

  bool _shouldRetry(DioException e) {
    return e.response == null &&
        (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError);
  }
}
