import 'package:dio/dio.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  const AuthApiException(this.message, {this.statusCode});

  factory AuthApiException.fromDio(
    DioException error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return AuthApiException(
      extractMessage(error, fallback: fallback),
      statusCode: error.response?.statusCode,
    );
  }

  static String extractMessage(
    DioException error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final data = error.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['message', 'detail', 'error', 'msg']) {
        final value = map[key];
        final text = _coerceMessage(value);
        if (text.isNotEmpty) {
          return userFacingMessage(text, fallback: fallback);
        }
      }

      final errors = map['errors'];
      final text = _coerceMessage(errors);
      if (text.isNotEmpty) {
        return userFacingMessage(text, fallback: fallback);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return userFacingMessage(data, fallback: fallback);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect. Please check your internet connection.';
      default:
        return fallback;
    }
  }

  static String userFacingMessage(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    final raw = error is AuthApiException ? error.message : error.toString();
    var message = raw.trim();
    if (message.isEmpty) return fallback;

    const exceptionPrefix = 'Exception:';
    while (message.startsWith(exceptionPrefix)) {
      message = message.substring(exceptionPrefix.length).trim();
    }

    final lower = message.toLowerCase();
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

    return isTechnical ? fallback : message;
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

  @override
  String toString() => message;
}
