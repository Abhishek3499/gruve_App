import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';

import 'package:gruve_app/features/auth/data/datasource/google_sign_in_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class GoogleAuthController {
  GoogleAuthController({GoogleAuthService? service})
    : _service = service ?? GoogleAuthService();

  final GoogleAuthService _service;

  Future<GoogleSignInResult> signIn() async {
    try {
      final res = await _service.signIn();

      if (res == null) {
        return const GoogleSignInResult.failure(null);
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
        return GoogleSignInResult.success(
          accessToken: data.accessToken,
          needsProfileSetup: data.needsProfileSetup || data.isNewUser,
        );
      }

      return GoogleSignInResult.failure(
        res.message.isNotEmpty
            ? res.message
            : 'Google sign-in failed. Please try again.',
      );
    } catch (e) {
      AppLogger.d('Google sign-in controller error: $e');
      return GoogleSignInResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback: 'Google sign-in failed. Please try again.',
        ),
      );
    }
  }
}

/// Immutable outcome of a Google Sign-In attempt, returned by
/// [GoogleAuthController.signIn] for the notifier/screen to act on.
class GoogleSignInResult {
  const GoogleSignInResult._({
    required this.isSuccess,
    this.accessToken,
    this.needsProfileSetup = false,
    this.errorMessage,
  });

  const GoogleSignInResult.failure(String? message)
    : this._(isSuccess: false, errorMessage: message);

  factory GoogleSignInResult.success({
    required String accessToken,
    required bool needsProfileSetup,
  }) => GoogleSignInResult._(
    isSuccess: true,
    accessToken: accessToken,
    needsProfileSetup: needsProfileSetup,
  );

  final bool isSuccess;
  final String? accessToken;
  final bool needsProfileSetup;
  final String? errorMessage;
}
