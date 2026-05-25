import 'package:flutter/foundation.dart';

import '../models/logout_model.dart';
import '../services/logout_service.dart';

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
    debugPrint('[Logout] Starting logout API process');

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
          debugPrint('[Logout] Logout API failed: ${res.message}');
        } else {
          debugPrint('[Logout] Logout API successful');
        }
      } else {
        debugPrint('[Logout] No tokens found, skipping API call');
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('[Logout] Logout API error: $e');
    } finally {
      isLoading = false;
      debugPrint('[Logout] Logout API process completed');
    }
  }
}
