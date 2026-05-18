
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/config/production_logger.dart';

/// Comprehensive debug logging system
/// Provides structured logging with different levels and categories
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal() {
    // Initialize with production logger
  }

  /// Log cache operations
  void cache(String operation, String key, {
    String? type,
    String? source,
    int? size,
    Duration? duration,
    bool? hit,
  }) {
    final parts = <String>['[CACHE]', operation, key];

    if (type != null) parts.add('[$type]');
    if (source != null) parts.add('($source)');
    if (hit != null) parts.add(hit ? 'HIT' : 'MISS');
    if (size != null) parts.add('${size}B');
    if (duration != null) parts.add('${duration.inMilliseconds}ms');

    final message = parts.join(' ');
    
    if (kDebugMode) {
      debugPrint(message);
    }
    
    // Also log to production logger
    logger.debug(message, tag: 'Cache');
  }

  /// Log network operations
  void network(String method, String endpoint, {
    int? statusCode,
    Duration? duration,
    int? responseSize,
    String? error,
    bool? fromCache,
    bool? isDuplicate,
    Map<String, dynamic>? properties,
  }) {
    final parts = <String>['[NET]', method, endpoint];

    if (statusCode != null) parts.add('($statusCode)');
    if (duration != null) parts.add('${duration.inMilliseconds}ms');
    if (responseSize != null) parts.add('${responseSize}B');
    if (fromCache == true) parts.add('[CACHE]');
    if (isDuplicate == true) parts.add('[DEDUP]');
    if (error != null) parts.add('ERROR:$error');
    if (properties != null) {
      properties.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    final message = parts.join(' ');
    
    if (error != null) {
      logger.error(message, tag: 'Network');
    } else {
      logger.debug(message, tag: 'Network');
    }
  }

  /// Log WebSocket events
  void socket(String event, {
    String? conversationId,
    String? userId,
    int? reconnectAttempts,
    String? error,
    Duration? connectionTime,
    Map<String, dynamic>? properties,
  }) {
    final parts = <String>['[SOCKET]', event];

    if (conversationId != null) parts.add('conv:$conversationId');
    if (userId != null) parts.add('user:$userId');
    if (reconnectAttempts != null) parts.add('attempt:$reconnectAttempts');
    if (connectionTime != null) parts.add('${connectionTime.inMilliseconds}ms');
    if (error != null) parts.add('ERROR:$error');
    if (properties != null) {
      properties.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    final message = parts.join(' ');
    
    if (error != null) {
      logger.error(message, tag: 'Socket');
    } else {
      logger.info(message, tag: 'Socket');
    }
  }

  /// Log performance metrics
  void performance(String operation, Duration duration, {
    Map<String, dynamic>? metadata,
    int? frameTime,
    double? fps,
    int? droppedFrames,
  }) {
    final parts = <String>['[PERF]', operation, '${duration.inMilliseconds}ms'];

    if (frameTime != null) parts.add('$frameTimeμs');
    if (fps != null) parts.add('${fps.toStringAsFixed(1)}fps');
    if (droppedFrames != null) parts.add('dropped:$droppedFrames');
    if (metadata != null) {
      metadata.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    // Direct logger call to avoid recursion
    if (kDebugMode) {
      debugPrint('⏱️ [PERF] $operation: ${duration.inMilliseconds}ms');
    }
    
    logger.performance(operation, duration, metadata: metadata);
  }

  /// Log UI state changes
  void ui(String component, String state, {
    String? previousState,
    Map<String, dynamic>? properties,
  }) {
    final parts = <String>['[UI]', component, state];

    if (previousState != null) parts.add('from:$previousState');
    if (properties != null) {
      properties.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    // Direct logger call to avoid recursion
    if (kDebugMode) {
      debugPrint(parts.join(' '));
    }
    
    logger.debug(parts.join(' '), tag: 'UI');
  }

  /// Log authentication events
  void auth(String event, {
    String? userId,
    String? method,
    String? error,
    Duration? duration,
  }) {
    final parts = <String>['[AUTH]', event];

    if (userId != null) parts.add('user:$userId');
    if (method != null) parts.add('method:$method');
    if (duration != null) parts.add('${duration.inMilliseconds}ms');
    if (error != null) parts.add('ERROR:$error');

    final message = parts.join(' ');
    
    if (error != null) {
      logger.error(message, tag: 'Auth');
    } else {
      logger.info(message, tag: 'Auth');
    }
  }

  /// Log user interactions
  void user(String action, {
    String? screen,
    String? target,
    Map<String, dynamic>? properties,
  }) {
    final parts = <String>['[USER]', action];

    if (screen != null) parts.add('screen:$screen');
    if (target != null) parts.add('target:$target');
    if (properties != null) {
      properties.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    logger.userAction(parts.join(' '), properties: properties);
  }

  /// Log navigation events
  void navigation(String from, String to, {
    String? method,
    Map<String, dynamic>? arguments,
  }) {
    final parts = <String>['[NAV]', '$from→$to'];

    if (method != null) parts.add('method:$method');
    if (arguments != null) {
      arguments.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    logger.debug(parts.join(' '), tag: 'Navigation');
  }

  /// Log repository operations
  void repository(String operation, String entity, {
    String? id,
    Map<String, dynamic>? data,
    String? error,
    Duration? duration,
    bool? fromCache,
  }) {
    final parts = <String>['[REPO]', operation, entity];

    if (id != null) parts.add('id:$id');
    if (fromCache == true) parts.add('[CACHE]');
    if (duration != null) parts.add('${duration.inMilliseconds}ms');
    if (data != null) {
      data.forEach((key, value) {
        parts.add('$key:$value');
      });
    }
    if (error != null) parts.add('ERROR:$error');

    final message = parts.join(' ');
    
    if (error != null) {
      logger.error(message, tag: 'Repository');
    } else {
      logger.debug(message, tag: 'Repository');
    }
  }

  /// Log provider state changes
  void provider(String name, String state, {
    String? previousState,
    Map<String, dynamic>? data,
    int? itemCount,
  }) {
    final parts = <String>['[PROVIDER]', name, state];

    if (previousState != null) parts.add('from:$previousState');
    if (itemCount != null) parts.add('items:$itemCount');
    if (data != null) {
      data.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    logger.debug(parts.join(' '), tag: 'Provider');
  }

  /// Log widget lifecycle
  void widget(String widgetName, String lifecycle, {
    Map<String, dynamic>? properties,
  }) {
    final parts = <String>['[WIDGET]', widgetName, lifecycle];

    if (properties != null) {
      properties.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    logger.debug(parts.join(' '), tag: 'Widget');
  }

  /// Log memory usage
  void memory({
    int? cacheSize,
    int? imageCacheSize,
    int? totalMemory,
    Map<String, dynamic>? details,
  }) {
    final parts = <String>['[MEMORY]'];

    if (cacheSize != null) parts.add('cache:${cacheSize}B');
    if (imageCacheSize != null) parts.add('images:${imageCacheSize}B');
    if (totalMemory != null) parts.add('total:${totalMemory}B');
    if (details != null) {
      details.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    logger.debug(parts.join(' '), tag: 'Memory');
  }

  /// Log image loading
  void image(String url, {
    String? operation,
    int? size,
    Duration? loadTime,
    String? error,
    bool? fromCache,
    String? source,
  }) {
    final parts = <String>['[IMAGE]', operation ?? 'LOAD', url];

    if (size != null) parts.add('${size}B');
    if (loadTime != null) parts.add('${loadTime.inMilliseconds}ms');
    if (fromCache == true) parts.add('[CACHE]');
    if (source != null) parts.add('($source)');
    if (error != null) parts.add('ERROR:$error');

    final message = parts.join(' ');
    
    if (error != null) {
      logger.error(message, tag: 'Image');
    } else {
      logger.debug(message, tag: 'Image');
    }
  }

  /// Log errors with context
  void error(String error, {
    String? context,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    bool? fatal,
    String? tag,
    Object? errorObj,
    StackTrace? stackTraceObj,
  }) {
    final parts = <String>['[ERROR]'];
    if (context != null) parts.add('context:$context');
    if (tag != null) parts.add('tag:$tag');
    if (fatal == true) parts.add('[FATAL]');
    if (metadata != null) {
      metadata.forEach((key, value) {
        parts.add('$key:$value');
      });
    }

    final message = parts.join(' ');
    
    logger.error(message, error: errorObj ?? error, stackTrace: stackTraceObj ?? (stackTrace != null ? StackTrace.fromString(stackTrace) : null));
    
    if (fatal == true) {
      developer.log('🚨 FATAL ERROR: $message', name: 'DebugLogger');
    }
  }

  /// Log debug messages
  void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final parts = <String>['[DEBUG]'];
      if (tag != null) parts.add('tag:$tag');
      parts.add(message);
      developer.log(parts.join(' '), name: 'DebugLogger');
    }
  }

  /// Log info messages
  void info(String message, {String? tag}) {
    if (kDebugMode) {
      final parts = <String>['[INFO]'];
      if (tag != null) parts.add('tag:$tag');
      parts.add(message);
      developer.log(parts.join(' '), name: 'DebugLogger');
    }
  }

  /// Log warning messages
  void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final parts = <String>['[WARNING]'];
      if (tag != null) parts.add('tag:$tag');
      parts.add(message);
      developer.log(parts.join(' '), name: 'DebugLogger');
    }
  }

  /// Create specialized logger for a component
  ComponentLogger forComponent(String componentName) {
    return ComponentLogger(componentName);
  }
}

/// Component-specific logger
class ComponentLogger {
  final String componentName;

  ComponentLogger(this.componentName);

  void debug(String message, {Map<String, dynamic>? properties}) {
    if (kDebugMode) {
      final parts = <String>['[$componentName]', message];
      if (properties != null) {
        properties.forEach((key, value) {
          parts.add('$key:$value');
        });
      }
      debugPrint(parts.join(' '));
    }
  }
  
  void info(String message, {Map<String, dynamic>? properties}) {
    if (kDebugMode) {
      final parts = <String>['[$componentName]', message];
      if (properties != null) {
        properties.forEach((key, value) {
          parts.add('$key:$value');
        });
      }
      debugPrint(parts.join(' '));
    }
  }
  
  void warning(String message, {Map<String, dynamic>? properties}) {
    if (kDebugMode) {
      final parts = <String>['[$componentName]', message];
      if (properties != null) {
        properties.forEach((key, value) {
          parts.add('$key:$value');
        });
      }
      debugPrint(parts.join(' '));
    }
  }
  
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final parts = <String>['[$componentName]', message];
      if (error != null) parts.add('ERROR:$error');
      debugPrint(parts.join(' '));
    }
  }

  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      final parts = <String>['[$componentName]', operation, '${duration.inMilliseconds}ms'];
      if (metadata != null) {
        metadata.forEach((key, value) {
          parts.add('$key:$value');
        });
      }
      debugPrint(parts.join(' '));
    }
  }

  void state(String state, {Map<String, dynamic>? properties}) {
    if (kDebugMode) {
      final parts = <String>['[$componentName]', state];
      if (properties != null) {
        properties.forEach((key, value) {
          parts.add('$key:$value');
        });
      }
      debugPrint(parts.join(' '));
    }
  }
}

/// Global debug logger instance
final debugLog = DebugLogger();

/// Extension for easy debug logging
extension DebugLogExtension on String {
  void logDebug({String? tag}) {
    if (kDebugMode) {
      debugLog.debug(this, tag: tag);
    }
  }
  
  void logInfo({String? tag}) {
    if (kDebugMode) {
      debugLog.info(this, tag: tag);
    }
  }
  
  void logWarning({String? tag}) {
    if (kDebugMode) {
      debugLog.warning(this, tag: tag);
    }
  }
  
  void logError({String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugLog.error(this, 
        tag: tag, 
        errorObj: error, 
        stackTraceObj: stackTrace);
    }
  }
}
