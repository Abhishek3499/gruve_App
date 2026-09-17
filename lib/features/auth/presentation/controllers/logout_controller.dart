import 'package:gruve_app/features/auth/data/services/logout_service.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';

class LogoutController {
  final LogoutService _service = LogoutService();

  /// Calls the logout API when a token is available. Returns an immutable
  /// [LogoutResult] describing whether the API call itself succeeded;
  /// callers preserve the previous behavior of proceeding with local
  /// session cleanup regardless of this result.
  Future<LogoutResult> logout({
    String? accessToken,
    String? refreshToken,
  }) async {
    authLogger.d('[Logout] Starting logout API process');

    try {
      final hasToken =
          (refreshToken != null && refreshToken.isNotEmpty) ||
          (accessToken != null && accessToken.isNotEmpty);

      if (!hasToken) {
        authLogger.d('[Logout] No tokens found, skipping API call');
        return const LogoutResult(isSuccess: true);
      }

      final res = await _service.logout(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (!res.success) {
        authLogger.d('[Logout] Logout API failed: ${res.message}');
        return LogoutResult(isSuccess: false, errorMessage: res.message);
      }

      authLogger.d('[Logout] Logout API successful');
      return const LogoutResult(isSuccess: true);
    } catch (e) {
      authLogger.d('[Logout] Logout API error: $e');
      return LogoutResult(isSuccess: false, errorMessage: e.toString());
    } finally {
      authLogger.d('[Logout] Logout API process completed');
    }
  }
}

/// Immutable outcome of the logout API call, returned by
/// [LogoutController.logout] for the notifier to log/act on.
class LogoutResult {
  const LogoutResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}
