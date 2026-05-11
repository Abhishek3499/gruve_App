import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler for production apps
/// Catches unhandled errors and reports them
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal() {
    _initializeErrorHandling();
  }

  /// Initialize global error handling
  void _initializeErrorHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Catch async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true; // Prevent default error dialog
    };
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final errorInfo = _extractErrorInfo(details);

    debugPrint('🚨 [ErrorHandler] Flutter Error: ${errorInfo.toString()}');

    // In production, send to crash reporting service
    if (!kDebugMode) {
      _reportError(errorInfo);
    }

    // Show user-friendly error in debug mode
    if (kDebugMode) {
      _showDebugErrorDialog(errorInfo);
    }
  }

  /// Handle platform-level errors
  void _handlePlatformError(Object error, StackTrace stack) {
    final errorInfo = ErrorInfo(
      error: error.toString(),
      stackTrace: stack.toString(),
      library: 'Platform',
      context: 'Async error outside Flutter framework',
      timestamp: DateTime.now(),
    );

    debugPrint('🚨 [ErrorHandler] Platform Error: ${errorInfo.toString()}');

    if (!kDebugMode) {
      _reportError(errorInfo);
    }
  }

  /// Handle custom application errors
  void handleAppError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? library,
    Map<String, dynamic>? extra,
  }) {
    final errorInfo = ErrorInfo(
      error: error.toString(),
      stackTrace: stackTrace?.toString() ?? '',
      library: library ?? 'App',
      context: context ?? 'Application error',
      timestamp: DateTime.now(),
      extra: extra,
    );

    debugPrint('🚨 [ErrorHandler] App Error: ${errorInfo.toString()}');

    if (!kDebugMode) {
      _reportError(errorInfo);
    }
  }

  /// Extract error information from FlutterErrorDetails
  ErrorInfo _extractErrorInfo(FlutterErrorDetails details) {
    return ErrorInfo(
      error: details.exception.toString(),
      stackTrace: details.stack?.toString() ?? '',
      library: details.library,
      context: details.context?.toString() ?? 'Widget tree',
      timestamp: DateTime.now(),
      extra: {
        'errorBuilder': details.errorBuilder.toString(),
        'informationCollector': details.informationCollector.toString(),
      },
    );
  }

  /// Report error to crash reporting service
  void _reportError(ErrorInfo errorInfo) {
    // TODO: Integrate with Firebase Crashlytics or similar service
    debugPrint(
      '📊 [ErrorHandler] Reporting error to crash service: ${errorInfo.error}',
    );

    // Example Firebase Crashlytics integration:
    // FirebaseCrashlytics.instance.recordError(
    //   errorInfo.error,
    //   fatal: false,
    //   information: [
    //     DiagnosticsProperty('library', errorInfo.library),
    //     DiagnosticsProperty('context', errorInfo.context),
    //     DiagnosticsProperty('timestamp', errorInfo.timestamp),
    //     if (errorInfo.extra != null) ...errorInfo.extra!.entries.map((e) => DiagnosticsProperty(e.key, e.value)),
    //   ],
    // );
  }

  /// Show debug error dialog
  void _showDebugErrorDialog(ErrorInfo errorInfo) {
    // In debug mode, you might want to show detailed error info
    debugPrint('🐛 [ErrorHandler] Debug Error Details:');
    debugPrint('  Error: ${errorInfo.error}');
    debugPrint('  Library: ${errorInfo.library}');
    debugPrint('  Context: ${errorInfo.context}');
    debugPrint('  Stack: ${errorInfo.stackTrace}');
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    }

    if (errorString.contains('auth') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please log in again.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Content not found. It may have been removed.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Create error widget for UI
  Widget createErrorWidget(Object error, VoidCallback? onRetry) {
    final message = getUserFriendlyMessage(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                textAlign: TextAlign.center,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error information container
class ErrorInfo {
  final String error;
  final String stackTrace;
  final String? library;
  final String? context;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;

  ErrorInfo({
    required this.error,
    required this.stackTrace,
    this.library,
    this.context,
    required this.timestamp,
    this.extra,
  });

  @override
  String toString() {
    return 'ErrorInfo('
        'error: $error, '
        'library: $library, '
        'context: $context, '
        'timestamp: $timestamp'
        ')';
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stackTrace': stackTrace,
      'library': library,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      ...?extra,
    };
  }
}

/// Extension for easy error handling in widgets
extension ErrorBoundary on Widget {
  /// Wrap widget with error boundary
  Widget withErrorBoundary({
    Widget Function(Object, StackTrace)? errorBuilder,
    String? errorContext,
  }) {
    return ErrorBoundary(
      child: this,
      errorBuilder: errorBuilder,
      errorContext: errorContext,
    );
  }
}

/// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object, StackTrace)? errorBuilder;
  final String? errorContext;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.errorContext,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (widget.errorContext != null &&
          details.context?.toString().contains(widget.errorContext!) == true) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!, _stackTrace!);
    }

    return widget.child;
  }
}
