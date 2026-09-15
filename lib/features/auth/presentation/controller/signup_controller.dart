import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/signup_service.dart';
import 'package:gruve_app/features/auth/data/dto/signup_request.dart';
import 'package:gruve_app/features/auth/data/dto/signup_response.dart';

/// Handles the signup API call. Loading state and field-level validation
/// errors are owned by the Signup Riverpod notifier, not here.
class SignupController {
  SignupController({SignupService? service}) : _service = service ?? SignupService();

  final SignupService _service;

  Future<SignupResult> signup({
    String? fullName,
    String? identifier,
    String? password,
    String? gender,
  }) async {
    try {
      final request = SignupRequest(
        fullName: fullName,
        identifier: identifier,
        password: password,
        gender: gender,
      );

      final response = await _service.signup(request);

      if (response.success == true && response.data != null) {
        return SignupResult.success(response);
      }

      return SignupResult.failure('Signup failed. Please try again.');
    } catch (e) {
      return SignupResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback: 'Please check your signup details and try again.',
        ),
      );
    }
  }
}

class SignupResult {
  const SignupResult._({
    required this.isSuccess,
    this.response,
    this.errorMessage,
  });

  factory SignupResult.success(SignupResponse response) =>
      SignupResult._(isSuccess: true, response: response);

  factory SignupResult.failure(String message) =>
      SignupResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final SignupResponse? response;
  final String? errorMessage;
}
