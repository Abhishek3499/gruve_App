import 'package:gruve_app/core/utils/app_logger.dart';

/// Debug logger for the auth feature. Routes through [AppLogger] with a
/// fixed `Auth` tag, so output is clean JSON in debug builds only.
/// Never log passwords, OTPs, tokens, headers, or full response bodies.
class AuthLogger {
  const AuthLogger();

  void d(Object? message) => AppLogger.d(message.toString(), tag: 'Auth');
}

final AuthLogger authLogger = const AuthLogger();
