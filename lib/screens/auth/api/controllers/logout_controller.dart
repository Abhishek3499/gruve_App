import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/logout_model.dart';
import '../services/logout_service.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint("🚪 [Logout] 🚪 Starting logout process");

    try {
      final hasToken =
          (refreshToken != null && refreshToken.isNotEmpty) ||
          (accessToken != null && accessToken.isNotEmpty);

      if (hasToken) {
        debugPrint("📡 [Logout] 📡 Calling logout API");
        final res = await _service.logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        response = res;

        if (!res.success) {
          debugPrint("❌ [Logout] ❌ Logout API failed: ${res.message}");
          errorMessage = res.message;
        } else {
          debugPrint("✅ [Logout] ✅ Logout API successful");
        }
      } else {
        debugPrint("⚠️ [Logout] ⚠️ No tokens found, skipping API call");
      }
    } catch (e) {
      debugPrint("💥 [Logout] 💥 Logout error: $e");
      errorMessage = e.toString();
    } finally {
      // 🔌 DISCONNECT WEBSOCKET ON LOGOUT
      debugPrint("🔌 [Logout] 🔌 Disconnecting websocket");
      SocketService().disconnect();
      debugPrint("🧹 [Logout] 🧹 WebSocket disconnected");
      
      debugPrint("🗑️ [Logout] 🗑️ Clearing tokens");
      await TokenStorage.clearTokens();
      debugPrint("✅ [Logout] ✅ Tokens cleared successfully");
    }

    isLoading = false;
    debugPrint("🏁 [Logout] 🏁 Logout process completed");
  }
}
