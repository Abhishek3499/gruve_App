import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/forgot_password_service.dart';

/// Sends the password-reset code. Loading state and field-level validation
/// errors are owned by the Forgot Password Riverpod notifier, not here.
class ForgotPasswordController {
  ForgotPasswordController({ForgotPasswordService? service})
      : _service = service ?? ForgotPasswordService();

  final ForgotPasswordService _service;

  Future<ForgotPasswordResult> sendResetLink(String identifier) async {
    try {
      await _service.sendResetLink(identifier: identifier);
      return const ForgotPasswordResult.success();
    } catch (e) {
      return ForgotPasswordResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback: 'We could not send the reset code. Please try again.',
        ),
      );
    }
  }
}

class ForgotPasswordResult {
  const ForgotPasswordResult._({required this.isSuccess, this.errorMessage});

  const ForgotPasswordResult.success() : this._(isSuccess: true);

  factory ForgotPasswordResult.failure(String message) =>
      ForgotPasswordResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final String? errorMessage;
}
