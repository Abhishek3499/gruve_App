import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Single centralized logging utility for the app.
/// All logging goes through here — no raw [debugPrint] in feature code.
/// Logs are suppressed automatically in release/profile builds and rendered
/// with the same pretty box-style printer used by [authLogger].
class AppLogger {
  AppLogger._();

  static bool _enableLogs = kDebugMode;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    filter: _AppLogFilter(),
  );

  /// Enable or disable logging (still no-op outside debug mode).
  static void setEnabled(bool enabled) {
    _enableLogs = enabled && kDebugMode;
  }

  static bool get isEnabled => _enableLogs;

  /// Debug log — primary method for general messages.
  static void d(String message, {String? tag}) {
    _logger.d(tag != null ? '[$tag] $message' : message);
  }

  /// Alias for [d].
  static void log(String message, {String? tag}) => d(message, tag: tag);

  /// Info log.
  static void i(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.d('ℹ️ $prefix$message');
  }

  /// Info alias.
  static void info(String message, {String? tag}) => i(message, tag: tag);

  /// Warning log.
  static void w(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.d('⚠️ $prefix$message');
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
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.e('❌ $prefix$message', error: error, stackTrace: stackTrace);
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
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.d('✅ $prefix$message');
  }

  /// API request log.
  static void api(String method, String endpoint, {Map<String, dynamic>? params}) {
    var message = '📡 API: $method $endpoint';
    if (params != null && params.isNotEmpty) {
      message += '\nParams: $params';
    }
    _logger.d(message);
  }

  /// Performance timing log.
  static void performance(String operation, Duration duration) {
    _logger.d('⚡ PERF: $operation took ${duration.inMilliseconds}ms');
  }

  /// Navigation log.
  static void navigation(String from, String to) {
    _logger.d('🧭 NAV: $from → $to');
  }

  /// State change log.
  static void state(String stateName, dynamic oldValue, dynamic newValue) {
    _logger.d('🔄 STATE: $stateName changed from $oldValue to $newValue');
  }
}

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => AppLogger.isEnabled;
}
