import 'package:gruve_app/core/utils/app_logger.dart';

/// Centralized logging utility for the camera feature. Routes through
/// [AppLogger] with a fixed `Camera` tag and per-action event names.
class CameraLogger {
  static const String _tag = 'Camera';

  /// Log camera initialization start
  static void logInitializationStart() => _log('init_start');

  /// Log successful camera initialization
  static void logInitializationSuccess() => _log('init_success');

  /// Log camera initialization failure
  static void logInitializationFailure(String error) =>
      _logError('init_failed', error);

  /// Log camera disposal start
  static void logDisposeStart() => _log('dispose_start');

  /// Log successful camera disposal
  static void logDisposeSuccess() => _log('dispose_success');

  /// Log camera flip action start
  static void logCameraFlipStart() => _log('flip_start');

  /// Log successful camera flip
  static void logCameraFlipSuccess() => _log('flip_success');

  /// Log camera flip failure
  static void logCameraFlipFailure(String error) => _logError('flip_failed', error);

  /// Log capture action start
  static void logCaptureStart() => _log('capture_start');

  /// Log successful image capture
  static void logCaptureSuccess(String imagePath) =>
      _log('capture_success', data: {'imagePath': imagePath});

  /// Log capture failure
  static void logCaptureFailure(String error) => _logError('capture_failed', error);

  /// Log flash toggle action
  static void logFlashToggle(String flashMode) =>
      _log('flash_toggle', data: {'mode': flashMode});

  /// Log general camera actions
  static void log(String message) => AppLogger.debug(_tag, 'log', message: message);

  /// Log camera controller state changes
  static void logStateChange(String state) =>
      _log('state_change', data: {'state': state});

  /// Log widget lifecycle events
  static void logLifecycle(String event) => AppLogger.debug(_tag, 'lifecycle', message: event);

  /// Log user interactions
  static void logUserAction(String action) => AppLogger.debug(_tag, 'user_action', message: action);

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    AppLogger.debug(
      _tag,
      'performance',
      data: {'operation': operation, 'durationMs': duration.inMilliseconds},
    );
  }

  static void _log(String event, {Map<String, dynamic>? data}) {
    AppLogger.debug(_tag, event, data: data);
  }

  static void _logError(String event, String error) {
    AppLogger.error(_tag, event, error: error);
  }

  /// Log error with stack trace for debugging
  static void logError(String message, [StackTrace? stackTrace]) {
    AppLogger.error(_tag, 'error', message: message, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void logWarning(String message) => AppLogger.warning(_tag, 'log', message: message);

  /// Log verbose debugging information
  static void logVerbose(String message) => AppLogger.debug(_tag, 'verbose', message: message);
}
