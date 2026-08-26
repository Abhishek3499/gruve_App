import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';

import 'package:gruve_app/features/auth/domain/entities/google_sign_in_model.dart';
import 'package:gruve_app/features/auth/data/datasource/google_sign_in_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class GoogleAuthController {
  GoogleAuthController({GoogleAuthService? service})
    : _service = service ?? GoogleAuthService();

  final GoogleAuthService _service;

  bool isLoading = false;
  String? errorMessage;
  GoogleSignInResponse? response;

  Future<bool> signIn() async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn();
      response = res;

      if (res == null) {
        return false;
      }

      if (res.success && res.data != null) {
        final data = res.data!;

        await AuthStateManager().onAuthSuccess(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          userId: data.userId,
        );

        ProfileIdentityService.instance.clearCachedLoggedInUserId();

        if (data.userId.trim().isNotEmpty) {
          ProfileIdentityService.instance.primeLoggedInUserId(data.userId);
        }

        AppLogger.d('Google sign-in tokens saved successfully');
        return true;
      }

      errorMessage = res.message.isNotEmpty
          ? res.message
          : 'Google sign-in failed. Please try again.';
      return false;
    } catch (e) {
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback: 'Google sign-in failed. Please try again.',
      );
      AppLogger.d('Google sign-in controller error: $e');
      return false;
    } finally {
      isLoading = false;
    }
  }

  bool get needsProfileSetup =>
      response?.data?.needsProfileSetup == true ||
      response?.data?.isNewUser == true;
}
