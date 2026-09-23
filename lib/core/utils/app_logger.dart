import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:gruve_app/core/utils/legacy_log_adapter.dart';
import 'package:gruve_app/core/utils/log_printer.dart';
import 'package:gruve_app/core/utils/log_sanitizer.dart';

/// Centralized application logger.
///
/// Logs are rendered as pretty JSON:
/// {
///   "level": "debug",
///   "tag": "API",
///   "event": "request_started",
///   "message": "...",
///   "data": {}
/// }
///
/// Debug/info logs are disabled in release builds.
/// Warning/error logs remain enabled.
///
/// Sensitive values such as tokens, passwords, OTPs and authorization
/// headers are automatically redacted (see [LogSanitizer]).
class AppLogger {
  AppLogger._();

  static bool _enabled = kDebugMode;

  static final Logger _logger = Logger(
    printer: AppLogPrinter(),
    filter: AppLogFilter(() => _enabled),
    level: Level.debug,
  );

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  static bool get isEnabled => _enabled;

  static void setEnabled(bool enabled) {
    _enabled = enabled && kDebugMode;
  }

  // ---------------------------------------------------------------------------
  // Structured logging
  // ---------------------------------------------------------------------------

  static void debug(
    String tag,
    String event, {
    String? message,
    Map<String, dynamic>? data,
  }) {
    _emit(level: 'debug', tag: tag, event: event, message: message, data: data);
  }

  static void info(
    String tag,
    String event, {
    String? message,
    Map<String, dynamic>? data,
  }) {
    _emit(level: 'info', tag: tag, event: event, message: message, data: data);
  }

  static void warning(
    String tag,
    String event, {
    String? message,
    Map<String, dynamic>? data,
  }) {
    _emit(
      level: 'warning',
      tag: tag,
      event: event,
      message: message,
      data: data,
    );
  }

  static void error(
    String tag,
    String event, {
    String? message,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final payload = <String, dynamic>{
      if (data != null) ...data,
      if (error != null) 'error': error.toString(),
    };

    _emit(
      level: 'error',
      tag: tag,
      event: event,
      message: message,
      data: payload.isEmpty ? null : payload,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy logging methods
  // ---------------------------------------------------------------------------

  static void d(String message, {String? tag}) {
    _legacy('debug', message, tag);
  }

  static void log(String message, {String? tag}) {
    d(message, tag: tag);
  }

  static void i(String message, {String? tag}) {
    _legacy('info', message, tag);
  }

  static void w(String message, {String? tag}) {
    _legacy('warning', message, tag);
  }

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final parsed = LegacyLogAdapter.parse(message, tag);

    _emit(
      level: 'error',
      tag: parsed.tag,
      event: 'log',
      message: parsed.message,
      data: error == null ? null : {'error': error.toString()},
      stackTrace: stackTrace,
    );
  }

  static void _legacy(String level, String message, String? tag) {
    final parsed = LegacyLogAdapter.parse(message, tag);

    _emit(level: level, tag: parsed.tag, event: 'log', message: parsed.message);
  }

  // ---------------------------------------------------------------------------
  // Core logger
  // ---------------------------------------------------------------------------

  static void _emit({
    required String level,
    String? tag,
    String? event,
    String? message,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    final isDebugLevel = level == 'debug' || level == 'info';

    if (isDebugLevel && !_enabled) {
      return;
    }

    try {
      final entry = <String, dynamic>{'level': level};

      final cleanTag = LogSanitizer.cleanText(tag);
      if (cleanTag != null && cleanTag.isNotEmpty) {
        entry['tag'] = cleanTag;
      }

      final cleanEvent = LogSanitizer.cleanText(event);
      if (cleanEvent != null && cleanEvent.isNotEmpty) {
        entry['event'] = cleanEvent;
      }

      final cleanMessage = LogSanitizer.cleanText(message);
      if (cleanMessage != null && cleanMessage.isNotEmpty) {
        entry['message'] = cleanMessage;
      }

      if (data != null) {
        final sanitizedData = LogSanitizer.sanitizeValue(data);

        if (sanitizedData is Map && sanitizedData.isNotEmpty) {
          entry['data'] = sanitizedData;
        }
      }

      final json = _encode(entry);

      switch (level) {
        case 'error':
          _logger.e(json, stackTrace: stackTrace);
          break;

        case 'warning':
          _logger.w(json);
          break;

        case 'info':
          _logger.i(json);
          break;

        default:
          _logger.d(json);
      }
    } catch (_) {
      // Logging must never crash the application.
    }
  }

  // ---------------------------------------------------------------------------
  // JSON encoding
  // ---------------------------------------------------------------------------

  // Pretty-printed (indented) JSON — a single compact line gets truncated by
  // the terminal/logcat once the payload grows, making it unreadable.
  // Indenting keeps every field visible across multiple lines instead.
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ', _toEncodable);

  static dynamic _toEncodable(dynamic value) {
    return value.toString();
  }

  static String _encode(Map<String, dynamic> entry) {
    try {
      return _encoder.convert(entry);
    } catch (error) {
      return _fallbackEncode(entry, error);
    }
  }

  static String _fallbackEncode(Map<String, dynamic> entry, Object error) {
    try {
      return _encoder.convert({
        'level': entry['level'],
        'event': entry['event'] ?? 'log',
        'message': 'unserializable log payload',
        'data': {'error': error.toString()},
      });
    } catch (_) {
      return '{"level":"${entry['level']}","message":"log encoding failed"}';
    }
  }
}
