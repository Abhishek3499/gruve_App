import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/api_exception.dart';

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
    final data = error.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final keysToCheck = const ['error', 'message', 'detail', 'msg', 'errors'];

      // 1. Try to find the first non-technical message in the preferred keys
      for (final key in keysToCheck) {
        final value = map[key];
        final text = _coerceMessage(value);
        if (text.isNotEmpty) {
          final userMsg = userFacingMessage(text, fallback: '');
          if (userMsg.isNotEmpty) {
            return userMsg;
          }
        }
      }

      // 2. Try to find any other non-technical field error in the map
      for (final entry in map.entries) {
        if (keysToCheck.contains(entry.key)) continue;
        final text = _coerceMessage(entry.value);
        if (text.isNotEmpty) {
          final userMsg = userFacingMessage(text, fallback: '');
          if (userMsg.isNotEmpty) {
            return userMsg;
          }
        }
      }

      // 3. Fallback: if all messages were technical/generic, return the first available one with the fallback
      for (final key in keysToCheck) {
        final value = map[key];
        final text = _coerceMessage(value);
        if (text.isNotEmpty) {
          return userFacingMessage(text, fallback: fallback);
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return userFacingMessage(data, fallback: fallback);
    }

    final innerError = error.error;
    if (innerError is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'Server is temporarily unavailable. Please try again later.';
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

}
