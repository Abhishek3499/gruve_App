import 'package:gruve_app/features/auth/core/auth_api_exception.dart';

import '../models/phone_login_model.dart';
import '../services/phone_login_services.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class PhoneSignInController {
  final PhoneSiginServices _service = PhoneSiginServices();

  bool isLoading = false;
  String? errorMessage;
  PhoneloginResponse? response;

  Future<void> signIn({required String phoneNumber}) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn(phoneNumber: phoneNumber);
      response = res;

      AppLogger.d('Phone login success=${res.success}');
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
      AppLogger.d('Phone login controller error: $e');
    } finally {
      isLoading = false;
    }
  }
}
