import 'package:flutter/material.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
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
    required String phone_number,
    required String email,
    required String type,
    required String otp,
    bool isLogin = false,
    bool isForgot = false, // ✅ ADD THIS
  }) async {
    isLoading = true;
    errorMessage = null;

    debugPrint("🧠 CONTROLLER HIT");
    debugPrint("👉 isForgot: $isForgot");
    debugPrint("👉 isLogin: $isLogin");
    debugPrint("👉 identifier: $identifier");
    debugPrint("👉 email: $email");
    debugPrint("👉 phone: $phone_number");

    try {
      final response = await _service.verifyOtp(
        identifier: identifier,
        phone_number: phone_number,
        email: email,
        type: type,
        otp: otp,
        isLogin: isLogin,
        isForgot: isForgot, // ✅ PASS
      );

      verifyOtpResponse = response;

      // ❗ DO NOT SAVE TOKENS IN FORGOT PASSWORD
      if (response.success) {
        if (response.data != null) {
          // ✅ LOGIN / SIGNUP FLOW
          if (!isForgot) {
            await TokenStorage.saveTokens(
              accessToken: response.data!.accessToken,
              refreshToken: response.data!.refreshToken,
            );
            ProfileIdentityService.instance.clearCachedLoggedInUserId();

            if (response.data!.userId.trim().isNotEmpty) {
              await TokenStorage.saveCurrentUserId(response.data!.userId);
              ProfileIdentityService.instance.primeLoggedInUserId(
                response.data!.userId,
              );
            }

            debugPrint("✅ TOKENS SAVED");
          }

          // ✅ FORGOT PASSWORD FLOW
          if (isForgot) {
            final resetToken = response.data!.reset_token;

            await TokenStorage.saveResetToken(resetToken!);

            debugPrint("🔐 RESET TOKEN SAVED");
          }
        }
      } else {
        errorMessage = response.message;
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
  }
}
