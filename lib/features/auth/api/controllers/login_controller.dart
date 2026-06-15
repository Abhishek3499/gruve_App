import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';

import '../models/login_model.dart';
import '../services/login_services.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class EmailSignInController {
  final EmailSignInService _service = EmailSignInService();

  bool isLoading = false;
  String? errorMessage;
  EmailSignInResponse? response;

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn(
        identifier: identifier,
        password: password,
      );

      response = res;

      AppLogger.d("✅ SUCCESS: ${res.success}");
      AppLogger.d("📩 MESSAGE: ${res.message}");

      // ✅ TOKEN SAVE SAFE
      if (res.success && res.data != null) {
        final accessToken = res.data!.accessToken;
        final refreshToken = res.data!.refreshToken;

        await AuthStateManager().onAuthSuccess(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: res.data!.userId,
        );
        ProfileIdentityService.instance.clearCachedLoggedInUserId();

        if (res.data!.userId.trim().isNotEmpty) {
          ProfileIdentityService.instance.primeLoggedInUserId(res.data!.userId);
        }

        AppLogger.d("✅ TOKENS SAVED SUCCESSFULLY");
      } else {
        errorMessage = _loginErrorMessage(res.message);
      }
    } catch (e) {
      errorMessage = _loginErrorMessage(e);
      AppLogger.d("❌ CONTROLLER ERROR: $e");
    } finally {
      isLoading = false;
    }
  }

  String _loginErrorMessage(Object? error) {
    final message = AuthApiException.userFacingMessage(
      error,
      fallback: 'Please enter the correct password.',
    );
    final lower = message.toLowerCase();

    if (lower.contains('invalid') ||
        lower.contains('incorrect') ||
        lower.contains('unauthorized') ||
        lower.contains('credential') ||
        lower.contains('password')) {
      return 'Please enter the correct password.';
    }

    return message;
  }
}
