import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/services/reset_password_service.dart';

/// Submits the new password. Loading state is owned by the Reset Password
/// Riverpod notifier, not here.
class ResetPasswordController {
  ResetPasswordController({ResetPasswordService? service})
    : _service = service ?? ResetPasswordService();

  final ResetPasswordService _service;

  Future<ResetPasswordResult> resetPassword({
    required String identifier,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _service.resetPassword(
        identifier: identifier,
        otp: otp,
        password: password,
      );

      return ResetPasswordResult(
        isSuccess: response.message.toLowerCase().contains('success'),
        message: response.message,
      );
    } catch (e) {
      return ResetPasswordResult(
        isSuccess: false,
        message: AuthApiException.userFacingMessage(
          e,
          fallback: 'Password could not be reset. Please try again.',
        ),
      );
    }
  }
}

class ResetPasswordResult {
  const ResetPasswordResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}
