import 'package:gruve_app/features/auth/core/auth_api_exception.dart';

import '../models/signup_request.dart';
import '../models/signup_response.dart';
import '../services/signup_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SignupController {
  bool isLoading = false;
  String? errorMessage;
  SignupResponse? signupResponse;

  final SignupService _service = SignupService();
  Future<void> signup({
    String? fullName,
    String? identifier,
    String? password,
    String? gender,
  }) async {
    isLoading = true;
    errorMessage = null;
    signupResponse = null;

    AppLogger.d("🚀 Signup Start");
    AppLogger.d("Name: $fullName");
    AppLogger.d("Identifier: $identifier");

    try {
      final request = SignupRequest(
        fullName: fullName,
        identifier: identifier,
        password: password,
        gender: gender,
      );

      signupResponse = await _service.signup(request);

      AppLogger.d("✅ User ID: ${signupResponse?.data?.id}");
    } catch (e) {
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback: 'Please check your signup details and try again.',
      );
      AppLogger.d("❌ Signup Error: $errorMessage");
    } finally {
      isLoading = false;
    }
  }
}
