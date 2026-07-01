import 'package:dio/dio.dart';

class AuthEndpointPaths {
  const AuthEndpointPaths._();

  static const Set<String> _skipAuthPaths = {
    'auth/login',
    'auth/google',
    'auth/signup',
    'auth/verify-otp',
    'auth/password-reset/verify-otp',
    'auth/forgot-password',
    'auth/password/reset/confirm',
    'auth/reset-password',
    'auth/refresh',
    'auth/resend-otp',
  };

  static String normalize(String path) {
    var normalized = path.trim();
    if (normalized.isEmpty) return normalized;

    final parsed = Uri.tryParse(normalized);
    if (parsed != null && parsed.hasScheme) {
      normalized = parsed.path;
    }

    normalized = normalized.split('?').first;
    normalized = normalized.replaceAll(RegExp(r'/+'), '/');
    normalized = normalized.replaceFirst(RegExp(r'^/+'), '');
    normalized = normalized.replaceFirst(RegExp(r'/+$'), '');
    return normalized.toLowerCase();
  }

  static bool shouldSkipAuth(String path) {
    final normalized = normalize(path);
    return _skipAuthPaths.any(
      (skipPath) =>
          normalized == skipPath || normalized.startsWith('$skipPath/'),
    );
  }

  static Options skipAuthOptions({Map<String, dynamic>? headers}) {
    return Options(headers: headers, extra: const {'skipAuth': true});
  }
}
