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

      // ✅ 🔥 SAVE TOKEN HERE
      if (response.token != null && response.token!.isNotEmpty) {
        await TokenStorage.saveToken(response.token!);
        print("TOKEN SAVED: ${response.token}");
      } else {
        print("⚠️ Token is null or empty");
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
  }
}
