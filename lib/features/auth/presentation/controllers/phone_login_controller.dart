import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/services/login_service.dart';

/// Requests a login OTP for a phone number via the shared
/// [EmailSignInService]. Loading state and field-level validation errors are
/// owned by the Phone Login Riverpod notifier, not here.
class PhoneSignInController {
  PhoneSignInController({EmailSignInService? service})
    : _service = service ?? EmailSignInService();

  final EmailSignInService _service;

  Future<PhoneLoginResult> requestOtp({required String phoneNumber}) async {
    try {
      final res = await _service.requestLoginOtp(identifier: phoneNumber);

      if (res.success) {
        return PhoneLoginResult.success();
      }

      return PhoneLoginResult.failure(
        AuthApiException.userFacingMessage(
          res.message,
          fallback: 'Please enter a valid phone number.',
        ),
      );
    } catch (e) {
      return PhoneLoginResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback: 'Please enter a valid phone number.',
        ),
      );
    }
  }
}

class PhoneLoginResult {
  const PhoneLoginResult._({required this.isSuccess, this.errorMessage});

  factory PhoneLoginResult.success() =>
      const PhoneLoginResult._(isSuccess: true);

  factory PhoneLoginResult.failure(String message) =>
      PhoneLoginResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final String? errorMessage;
}
