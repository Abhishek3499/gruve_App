import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/logout_model.dart';
import '../services/logout_service.dart';

class LogoutController {
  final LogoutService _service = LogoutService();
  bool isLoading = false;
  String? errorMessage;
  LogoutResponse? response;

  Future<void> logout() async {
    isLoading = true;
    errorMessage = null;

    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      final accessToken = await TokenStorage.getAccessToken();

      final hasToken =
          (refreshToken != null && refreshToken.isNotEmpty) ||
          (accessToken != null && accessToken.isNotEmpty);

      if (hasToken) {
        final res = await _service.logout();
        response = res;

        if (!res.success) {
          errorMessage = res.message;
        }
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      await TokenStorage.clearTokens();
    }

    isLoading = false;
  }
}
