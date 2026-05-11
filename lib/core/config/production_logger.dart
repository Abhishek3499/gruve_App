import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/config/environment_config.dart';

/// Production-safe logger
/// Disables debug prints in release mode
class ProductionLogger {
  static final ProductionLogger _instance = ProductionLogger._internal();
  factory ProductionLogger() => _instance;
  ProductionLogger._internal();

  /// Log debug messages
  void debug(String message, {String? tag}) {
    if (EnvironmentConfig.enableLogging && kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔍 $prefix$message');
    }
  }

  /// Log info messages
  void info(String message, {String? tag}) {
    if (EnvironmentConfig.enableLogging) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $prefix$message');
    }
  }

  /// Log warning messages
  void warning(String message, {String? tag}) {
    if (EnvironmentConfig.enableLogging) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $prefix$message');
    }
  }

  /// Log error messages
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (EnvironmentConfig.enableLogging) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ $prefix$message');
      
      if (error != null) {
        debugPrint('❌ $prefix Error: $error');
      }
      
      if (stackTrace != null) {
        debugPrint('❌ $prefix Stack: $stackTrace');
      }
    }
    
    // In production, send to crash reporting
    if (!kDebugMode && EnvironmentConfig.enableCrashReporting) {
      // TODO: Send to Firebase Crashlytics or similar
      // FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Log performance metrics
  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    if (EnvironmentConfig.enableLogging) {
      final metadataStr = metadata != null 
          ? ' | ${metadata.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
          : '';
      debugPrint('⏱️ [PERF] $operation: ${duration.inMilliseconds}ms$metadataStr');
    }
  }

  /// Log network requests
  void network(String method, String endpoint, int statusCode, Duration duration, {
    int? responseSize,
    Map<String, dynamic>? metadata,
  }) {
    if (EnvironmentConfig.enableLogging) {
      final sizeStr = responseSize != null ? ' | Size: ${responseSize}B' : '';
      final metadataStr = metadata != null 
          ? ' | ${metadata.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
          : '';
      
      final statusIcon = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint('🌐 [NET] $statusIcon $method $endpoint (${statusCode}) | ${duration.inMilliseconds}ms$sizeStr$metadataStr');
    }
  }

  /// Log user actions
  void userAction(String action, {Map<String, dynamic>? properties}) {
    if (EnvironmentConfig.enableLogging) {
      final propsStr = properties != null 
          ? ' | ${properties.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
          : '';
      debugPrint('👤 [USER] $action$propsStr');
    }
    
    // In production, send to analytics
    if (!kDebugMode && EnvironmentConfig.isFeatureEnabled('analytics')) {
      // TODO: Send to Firebase Analytics or similar
      // FirebaseAnalytics.instance.logEvent(
      //   name: action,
      //   parameters: properties,
      // );
    }
  }

  /// Log WebSocket events
  void socket(String event, {Map<String, dynamic>? data}) {
    if (EnvironmentConfig.enableLogging) {
      final dataStr = data != null ? ' | $data' : '';
      debugPrint('🔌 [SOCKET] $event$dataStr');
    }
  }

  /// Log cache operations
  void cache(String operation, String key, {String? type, Duration? duration}) {
    if (EnvironmentConfig.enableLogging) {
      final typeStr = type != null ? ' [$type]' : '';
      final durationStr = duration != null ? ' | ${duration.inMilliseconds}ms' : '';
      debugPrint('💾 [CACHE] $operation$typeStr $key$durationStr');
    }
  }

  /// Log authentication events
  void auth(String event, {String? userId, Map<String, dynamic>? metadata}) {
    if (EnvironmentConfig.enableLogging) {
      final userStr = userId != null ? ' | User: $userId' : '';
      final metadataStr = metadata != null 
          ? ' | ${metadata.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
          : '';
      debugPrint('🔐 [AUTH] $event$userStr$metadataStr');
    }
  }

  /// Create specialized logger for a specific tag
  _TaggedLogger withTag(String tag) {
    return _TaggedLogger(tag);
  }
}

/// Tagged logger for specific modules
class _TaggedLogger {
  final String tag;
  final ProductionLogger _logger = ProductionLogger();

  _TaggedLogger(this.tag);

  void debug(String message) => _logger.debug(message, tag: tag);
  void info(String message) => _logger.info(message, tag: tag);
  void warning(String message) => _logger.warning(message, tag: tag);
  void error(String message, {Object? error, StackTrace? stackTrace}) => 
      _logger.error(message, tag: tag, error: error, stackTrace: stackTrace);
  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) => 
      _logger.performance(operation, duration, metadata: metadata);
  void network(String method, String endpoint, int statusCode, Duration duration, {
        int? responseSize, Map<String, dynamic>? metadata}) => 
      _logger.network(method, endpoint, statusCode, duration, 
          responseSize: responseSize, metadata: metadata);
  void userAction(String action, {Map<String, dynamic>? properties}) => 
      _logger.userAction(action, properties: properties);
  void socket(String event, {Map<String, dynamic>? data}) => 
      _logger.socket(event, data: data);
  void cache(String operation, String key, {String? type, Duration? duration}) => 
      _logger.cache(operation, key, type: type, duration: duration);
  void auth(String event, {String? userId, Map<String, dynamic>? metadata}) => 
      _logger.auth(event, userId: userId, metadata: metadata);
}

/// Global logger instance
final logger = ProductionLogger();

/// Extension for easy logging
extension LoggerExtension on String {
  void logDebug({String? tag}) => logger.debug(this, tag: tag);
  void logInfo({String? tag}) => logger.info(this, tag: tag);
  void logWarning({String? tag}) => logger.warning(this, tag: tag);
  void logError({String? tag, Object? error, StackTrace? stackTrace}) => 
      logger.error(this, tag: tag, error: error, stackTrace: stackTrace);
}
