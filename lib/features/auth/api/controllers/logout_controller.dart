
import '../models/logout_model.dart';
import '../services/logout_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class LogoutController {
  final LogoutService _service = LogoutService();
  bool isLoading = false;
  String? errorMessage;
  LogoutResponse? response;

  Future<void> logout({
    String? accessToken,
    String? refreshToken,
  }) async {
    isLoading = true;
    errorMessage = null;
    AppLogger.d('[Logout] Starting logout API process');

    try {
      final hasToken =
          (refreshToken != null && refreshToken.isNotEmpty) ||
          (accessToken != null && accessToken.isNotEmpty);

      if (hasToken) {
        final res = await _service.logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        response = res;

        if (!res.success) {
          errorMessage = res.message;
          AppLogger.d('[Logout] Logout API failed: ${res.message}');
        } else {
          AppLogger.d('[Logout] Logout API successful');
        }
      } else {
        AppLogger.d('[Logout] No tokens found, skipping API call');
      }
    } catch (e) {
      errorMessage = e.toString();
      AppLogger.d('[Logout] Logout API error: $e');
    } finally {
      isLoading = false;
      AppLogger.d('[Logout] Logout API process completed');
    }
  }
}
