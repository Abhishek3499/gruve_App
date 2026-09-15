import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/services/login_service.dart';

/// Handles the email/password sign-in call and its post-login side effects
/// (token save, profile identity priming). Loading state and field-level
/// validation errors are owned by `AuthUiProvider`, not here.
class LoginController {
  LoginController({EmailSignInService? service})
      : _service = service ?? EmailSignInService();

  final EmailSignInService _service;

  Future<LoginResult> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _service.signIn(
        identifier: identifier,
        password: password,
      );

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

        return LoginResult.success(accessToken: data.accessToken);
      }

      return LoginResult.failure(_errorMessage(res.message));
    } catch (e) {
      return LoginResult.failure(_errorMessage(e));
    }
  }

  String _errorMessage(Object? error) => AuthApiException.userFacingMessage(
        error,
        fallback: 'The provided credentials are incorrect.',
      );
}

class LoginResult {
  const LoginResult._({
    required this.isSuccess,
    this.accessToken,
    this.errorMessage,
  });

  factory LoginResult.success({required String accessToken}) =>
      LoginResult._(isSuccess: true, accessToken: accessToken);

  factory LoginResult.failure(String message) =>
      LoginResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final String? accessToken;
  final String? errorMessage;
}
