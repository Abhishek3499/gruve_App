import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';

class AuthEndpointPaths {
  const AuthEndpointPaths._();

  static final Set<String> _skipAuthPaths = {
    ApiConstants.login,
    ApiConstants.googleSignIn,
    ApiConstants.signup,
    ApiConstants.verifyOtp,
    ApiConstants.passwordResetVerifyOtp,
    ApiConstants.forgotPassword,
    ApiConstants.passwordResetConfirm,
    ApiConstants.resetPassword,
    ApiConstants.refreshToken,
    ApiConstants.resendOtp,
  }.map(normalize).toSet();

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
