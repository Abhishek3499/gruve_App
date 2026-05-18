import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app
/// Automatically disables logs in release mode
class AppLogger {
  static bool _enableLogs = kDebugMode;
  
  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _enableLogs = enabled && kDebugMode;
  }
  
  /// Log a debug message
  static void log(String message, {String? tag}) {
    if (!_enableLogs) return;
    
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('$prefix$message');
  }
  
  /// Log an info message
  static void info(String message, {String? tag}) {
    if (!_enableLogs) return;
    
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('ℹ️ $prefix$message');
  }
  
  /// Log a warning message
  static void warning(String message, {String? tag}) {
    if (!_enableLogs) return;
    
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('⚠️ $prefix$message');
  }
  
  /// Log an error message (always shown, even in release)
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('❌ $prefix$message');
    
    if (error != null) {
      debugPrint('Error: $error');
    }
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
  
  /// Log a success message
  static void success(String message, {String? tag}) {
    if (!_enableLogs) return;
    
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('✅ $prefix$message');
  }
  
  /// Log an API call
  static void api(String method, String endpoint, {Map<String, dynamic>? params}) {
    if (!_enableLogs) return;
    
    debugPrint('📡 API: $method $endpoint');
    if (params != null && params.isNotEmpty) {
      debugPrint('   Params: $params');
    }
  }
  
  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    if (!_enableLogs) return;
    
    debugPrint('⚡ PERF: $operation took ${duration.inMilliseconds}ms');
  }
  
  /// Log navigation
  static void navigation(String from, String to) {
    if (!_enableLogs) return;
    
    debugPrint('🧭 NAV: $from → $to');
  }
  
  /// Log state changes
  static void state(String stateName, dynamic oldValue, dynamic newValue) {
    if (!_enableLogs) return;
    
    debugPrint('🔄 STATE: $stateName changed from $oldValue to $newValue');
  }
}
