import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/api_exception.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class AuthApiException extends ApiException {
  const AuthApiException(super.message, {super.statusCode, super.type});

  factory AuthApiException.fromDio(
    DioException error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return AuthApiException(
      extractMessage(error, fallback: fallback),
      statusCode: error.response?.statusCode,
      type: error.type.name,
    );
  }

  static String extractMessage(
    DioException error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    // Keep detailed logs only in debug mode
    if (kDebugMode) {
      AppLogger.d('[AuthApiException] Extracting message from error: $error');
      final data = error.response?.data;
      if (data != null) {
        AppLogger.d('[AuthApiException] Error response data: $data');
      }
    }

    final data = error.response?.data;
    String? backendMessage;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final keysToCheck = const ['error', 'message', 'detail', 'msg', 'errors'];

      for (final key in keysToCheck) {
        final value = map[key];
        final text = _coerceMessage(value);
        if (text.isNotEmpty) {
          backendMessage = text;
          break;
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      backendMessage = data;
    }

    return mapErrorToProductionMessage(
      error: backendMessage ?? error,
      statusCode: error.response?.statusCode,
      errorTypeName: error.type.name,
      fallback: fallback,
    );
  }

  static String userFacingMessage(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    // Keep detailed logs only in debug mode
    if (kDebugMode) {
      AppLogger.d('[AuthApiException] User facing check: $error');
    }

    return mapErrorToProductionMessage(
      error: error,
      fallback: fallback,
    );
  }

  /// Maps technical error details and transient status codes directly to
  /// production-friendly user messages, categorizing them cleanly.
  static String mapErrorToProductionMessage({
    required Object? error,
    int? statusCode,
    String? errorTypeName,
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    final rawString = error is AuthApiException
        ? error.message
        : (error is DioException ? (error.message ?? error.toString()) : error.toString());
    final lower = rawString.toLowerCase();

    // 1. Connection / Request Timeout
    final isTimeout = errorTypeName == 'connectionTimeout' ||
        errorTypeName == 'receiveTimeout' ||
        errorTypeName == 'sendTimeout' ||
        (error is DioException && (
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout
        )) ||
        lower.contains('timeout') ||
        lower.contains('time out');

    if (isTimeout) {
      return "We're having trouble connecting to the server. Please try again.";
    }

    // 2. No Internet
    final isNetwork = errorTypeName == 'connectionError' ||
        (error is DioException && error.type == DioExceptionType.connectionError) ||
        (error is DioException && error.error is SocketException) ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('network_error') ||
        lower.contains('no internet connection') ||
        lower.contains('no internet') ||
        lower.contains('connecterror');

    if (isNetwork) {
      return "No internet connection. Please check your connection and try again.";
    }

    // 3. Server Temporarily Unavailable (502/503/504/5xx)
    final isServerDown = (statusCode != null && (statusCode == 502 || statusCode == 503 || statusCode == 504 || statusCode == 500)) ||
        (error is DioException && error.response?.statusCode != null &&
            (error.response!.statusCode == 502 || error.response!.statusCode == 503 || error.response!.statusCode == 504 || error.response!.statusCode == 500)) ||
        lower.contains('502 bad gateway') ||
        lower.contains('503 service unavailable') ||
        lower.contains('504 gateway timeout') ||
        lower.contains('server error') ||
        lower.contains('internal server error');

    if (isServerDown) {
      return "Server is temporarily unavailable. Please try again in a few minutes.";
    }

    // 4. Invalid/Wrong/Expired OTP (checked before the generic session-expired
    // check below, since backend OTP-failure text often also contains "expired"
    // or comes back with a 401/403 status, which would otherwise be misread as
    // a session timeout instead of a bad OTP).
    final isOtpError = lower.contains('otp') &&
        (lower.contains('invalid') ||
            lower.contains('incorrect') ||
            lower.contains('wrong') ||
            lower.contains('mismatch') ||
            lower.contains('expired') ||
            lower.contains('does not match') ||
            lower.contains('failed'));

    if (isOtpError) {
      return "OTP does not match. Please enter the valid OTP sent to you.";
    }

    // 5. Session Expired
    final isSessionExpired = statusCode == 401 || statusCode == 403 ||
        (error is DioException && (error.response?.statusCode == 401 || error.response?.statusCode == 403)) ||
        lower.contains('expired') ||
        lower.contains('token_not_valid') ||
        lower.contains('unauthorized') ||
        lower.contains('session expired') ||
        lower.contains('token expired') ||
        lower.contains('token_expired') ||
        lower.contains('signature has expired');

    if (isSessionExpired) {
      return "Your session has expired. Please sign in again.";
    }

    // 6. Invalid Credentials (Precise matching to avoid blocking field validation)
    final isCredentialsError = lower.contains('invalid credentials') ||
        lower.contains('incorrect credentials') ||
        lower.contains('wrong password') ||
        lower.contains('incorrect password') ||
        lower.contains('invalid login credentials') ||
        lower == 'user not found' ||
        lower == 'unauthorized' ||
        lower == 'invalid username or password';

    if (isCredentialsError) {
      return "The provided credentials are incorrect.";
    }

    // Clean formatting and remove any raw technical prefixes
    var cleanMessage = rawString.trim();
    const exceptionPrefix = 'Exception:';
    while (cleanMessage.startsWith(exceptionPrefix)) {
      cleanMessage = cleanMessage.substring(exceptionPrefix.length).trim();
    }

    final isTechnical =
        lower == 'null' ||
        lower.contains('request failed') ||
        lower.contains('dioexception') ||
        lower.contains('http status') ||
        lower.contains('status code') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('failed host lookup');

    if (isTechnical || cleanMessage.isEmpty || cleanMessage.contains('{') || cleanMessage.contains('}')) {
      return "Something went wrong. Please try again.";
    }

    return cleanMessage;
  }

  static String _coerceMessage(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is List && value.isNotEmpty) {
      return _coerceMessage(value.first);
    }
    if (value is Map && value.isNotEmpty) {
      for (final item in value.values) {
        final text = _coerceMessage(item);
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }
}
