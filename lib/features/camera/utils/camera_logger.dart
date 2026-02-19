import 'package:flutter/foundation.dart';

/// Centralized logging utility for camera feature
/// Provides structured debug logging with consistent formatting
class CameraLogger {
  static const String _tag = '📷 CameraFeature';
  
  /// Log camera initialization start
  static void logInitializationStart() {
    _log('INIT', 'Camera initialization started');
  }

  /// Log successful camera initialization
  static void logInitializationSuccess() {
    _log('SUCCESS', 'Camera initialized successfully');
  }

  /// Log camera initialization failure
  static void logInitializationFailure(String error) {
    _log('ERROR', 'Camera initialization failed: $error');
  }

  /// Log camera disposal start
  static void logDisposeStart() {
    _log('DISPOSE', 'Camera disposal started');
  }

  /// Log successful camera disposal
  static void logDisposeSuccess() {
    _log('SUCCESS', 'Camera disposed successfully');
  }

  /// Log camera flip action start
  static void logCameraFlipStart() {
    _log('FLIP', 'Camera flip started');
  }

  /// Log successful camera flip
  static void logCameraFlipSuccess() {
    _log('SUCCESS', 'Camera flipped successfully');
  }

  /// Log camera flip failure
  static void logCameraFlipFailure(String error) {
    _log('ERROR', 'Camera flip failed: $error');
  }

  /// Log capture action start
  static void logCaptureStart() {
    _log('CAPTURE', 'Image capture started');
  }

  /// Log successful image capture
  static void logCaptureSuccess(String imagePath) {
    _log('SUCCESS', 'Image captured successfully: $imagePath');
  }

  /// Log capture failure
  static void logCaptureFailure(String error) {
    _log('ERROR', 'Image capture failed: $error');
  }

  /// Log flash toggle action
  static void logFlashToggle(String flashMode) {
    _log('FLASH', 'Flash toggled to: $flashMode');
  }

  /// Log general camera actions
  static void log(String message) {
    _log('INFO', message);
  }

  /// Log camera controller state changes
  static void logStateChange(String state) {
    _log('STATE', 'Camera state changed: $state');
  }

  /// Log widget lifecycle events
  static void logLifecycle(String event) {
    _log('LIFECYCLE', event);
  }

  /// Log user interactions
  static void logUserAction(String action) {
    _log('USER', action);
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    _log('PERF', '$operation completed in ${duration.inMilliseconds}ms');
  }

  /// Internal logging method
  static void _log(String level, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      debugPrint('[$_tag] [$timestamp] [$level] $message');
    }
  }

  /// Log error with stack trace for debugging
  static void logError(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log('ERROR', message);
      if (stackTrace != null) {
        debugPrint('[$_tag] StackTrace: $stackTrace');
      }
    }
  }

  /// Log warning messages
  static void logWarning(String message) {
    _log('WARNING', message);
  }

  /// Log verbose debugging information
  static void logVerbose(String message) {
    if (kDebugMode) {
      _log('VERBOSE', message);
    }
  }
}
