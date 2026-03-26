import 'package:gruve_app/screens/auth/token_storage.dart' show TokenStorage;

import '../services/verify_otp_service.dart';
import '../models/verify_otp_response.dart';

class VerifyotpController {
  final VerifyOtpService _service = VerifyOtpService();

  bool isLoading = false;
  String? errorMessage;
  VerifyOtpResponse? verifyOtpResponse;
  Future<void> verifyOtp({
    required String identifier,
    required String type,
    required String otp,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final response = await _service.verifyOtp(
        identifier: identifier,
        type: type,
        otp: otp,
      );

      verifyOtpResponse = response;

      // ✅ SAFE CHECK
      if (response.success && response.data != null) {
        await TokenStorage.saveTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );

        print("✅ TOKENS SAVED");
      } else {
        errorMessage = response.message;
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
  }
}
