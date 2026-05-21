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
        if (text.isNotEmpty) return text;
      }

      final errors = map['errors'];
      final text = _coerceMessage(errors);
      if (text.isNotEmpty) return text;
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
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
