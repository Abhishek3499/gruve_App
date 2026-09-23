import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized API request/response/error logger.
///
/// Emits exactly one compact JSON object per API call — request,
/// response and (on failure) error all in a single line, similar to a
/// Postman console view. Only active in debug builds; sensitive fields
/// (passwords, tokens, secrets, etc.) are masked before printing.
class ApiLogger {
  ApiLogger._();

  // Pretty-printed (indented) JSON. A compact single line gets truncated by
  // the terminal/logcat on large response bodies, making it unreadable —
  // indenting keeps every field visible across multiple lines instead.
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  static const Set<String> _sensitiveKeys = {
    'password',
    'confirmpassword',
    'otp',
    'accesstoken',
    'refreshtoken',
    'resettoken',
    'authorization',
    'cookie',
    'clientsecret',
    'secret',
    'apikey',
  };

  static void logResponse(Response<dynamic> response) {
    if (!kDebugMode) return;

    _print(<String, dynamic>{
      'type': 'API',
      'request': _requestMap(response.requestOptions),
      'response': _responseMap(response.statusCode, response.data),
    });
  }

  static void logError(DioException error) {
    if (!kDebugMode) return;

    final response = error.response;

    _print(<String, dynamic>{
      'type': 'API',
      'request': _requestMap(error.requestOptions),
      'response': _responseMap(response?.statusCode, response?.data),
      'error': {
        'type': error.type.name,
        'message': error.message ?? error.toString(),
      },
    });
  }

  static Map<String, dynamic> _requestMap(RequestOptions options) {
    return {
      'method': options.method,
      'url': options.uri.toString(),
      'headers': _mask(options.headers),
      if (options.queryParameters.isNotEmpty)
        'queryParameters': _mask(options.queryParameters),
      if (options.data != null) 'body': _mask(_normalizeBody(options.data)),
    };
  }

  static Map<String, dynamic> _responseMap(int? statusCode, dynamic data) {
    return {'statusCode': statusCode, 'body': _mask(data)};
  }

  static dynamic _normalizeBody(dynamic data) {
    if (data is FormData) {
      return {
        'fields': {for (final field in data.fields) field.key: field.value},
        'files': data.files
            .map((f) => {'field': f.key, 'filename': f.value.filename})
            .toList(),
      };
    }
    return data;
  }

  static dynamic _mask(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, v) {
        final keyString = key.toString();
        result[keyString] = _isSensitiveKey(keyString) ? '***' : _mask(v);
      });
      return result;
    }
    if (value is Iterable) {
      return value.map(_mask).toList();
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    return _sensitiveKeys.any((sensitive) => normalized.contains(sensitive));
  }

  static void _print(Map<String, dynamic> log) {
    try {
      final pretty = _encoder.convert(log);
      // Print line-by-line so a long single-line value can't get truncated
      // by platform console limits (JsonEncoder.withIndent already puts
      // most keys on their own line).
      for (final line in pretty.split('\n')) {
        debugPrint(line);
      }
    } catch (_) {
      // Logging must never crash the app.
      debugPrint('{"type":"API","error":{"message":"log encoding failed"}}');
    }
  }
}
