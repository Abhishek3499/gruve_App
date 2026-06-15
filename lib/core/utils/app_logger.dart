import 'package:flutter/foundation.dart';

/// Single centralized logging utility for the app.
/// All logging goes through here — no raw [debugPrint] in feature code.
/// Logs are suppressed automatically in release/profile builds.
class AppLogger {
  AppLogger._();

  static bool _enableLogs = kDebugMode;

  /// Enable or disable logging (still no-op outside debug mode).
  static void setEnabled(bool enabled) {
    _enableLogs = enabled && kDebugMode;
  }

  static bool get isEnabled => _enableLogs;

  /// Debug log — primary method for general messages.
  static void d(String message, {String? tag}) {
    if (!_enableLogs) return;
    _emit(tag != null ? '[$tag] $message' : message);
  }

  /// Alias for [d].
  static void log(String message, {String? tag}) => d(message, tag: tag);

  /// Info log.
  static void i(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag] ' : '';
    _emit('ℹ️ $prefix$message');
  }

  /// Info alias.
  static void info(String message, {String? tag}) => i(message, tag: tag);

  /// Warning log.
  static void w(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag] ' : '';
    _emit('⚠️ $prefix$message');
  }

  /// Warning alias.
  static void warning(String message, {String? tag}) => w(message, tag: tag);

  /// Error log (debug-only; use crash reporting separately for production).
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag] ' : '';
    _emit('❌ $prefix$message');
    if (error != null) {
      _emit('Error: $error');
    }
    if (stackTrace != null) {
      _emit('StackTrace: $stackTrace');
    }
  }

  /// Error alias.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      e(message, tag: tag, error: error, stackTrace: stackTrace);

  /// Success log.
  static void success(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag] ' : '';
    _emit('✅ $prefix$message');
  }

  /// API request log.
  static void api(String method, String endpoint, {Map<String, dynamic>? params}) {
    if (!_enableLogs) return;
    _emit('📡 API: $method $endpoint');
    if (params != null && params.isNotEmpty) {
      _emit('   Params: $params');
    }
  }

  /// Performance timing log.
  static void performance(String operation, Duration duration) {
    if (!_enableLogs) return;
    _emit('⚡ PERF: $operation took ${duration.inMilliseconds}ms');
  }

  /// Navigation log.
  static void navigation(String from, String to) {
    if (!_enableLogs) return;
    _emit('🧭 NAV: $from → $to');
  }

  /// State change log.
  static void state(String stateName, dynamic oldValue, dynamic newValue) {
    if (!_enableLogs) return;
    _emit('🔄 STATE: $stateName changed from $oldValue to $newValue');
  }

  static void _emit(String message) {
    debugPrint(message);
  }
}
