import 'package:gruve_app/features/auth/core/auth_api_exception.dart';

import '../models/login_model.dart';
import '../services/login_services.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class PhoneSignInController {
  final EmailSignInService _service = EmailSignInService();

  bool isLoading = false;
  String? errorMessage;
  EmailSignInResponse? response;

  Future<void> requestOtp({required String phoneNumber}) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.requestLoginOtp(identifier: phoneNumber);
      response = res;

      AppLogger.d('Phone login OTP requested success=${res.success}');
      if (!res.success) {
        errorMessage = AuthApiException.userFacingMessage(
          res.message,
          fallback: 'Please enter a valid phone number.',
        );
      }
    } catch (e) {
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback: 'Please enter a valid phone number.',
      );
      AppLogger.d('Phone login OTP request error: $e');
    } finally {
      isLoading = false;
    }
  }
}
