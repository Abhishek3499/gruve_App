import 'package:flutter/material.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/token_storage.dart' show TokenStorage;

import '../models/verify_otp_response.dart';
import '../services/verify_otp_service.dart';

class VerifyotpController {
  final VerifyOtpService _service = VerifyOtpService();

  bool isLoading = false;
  String? errorMessage;
  VerifyOtpResponse? verifyOtpResponse;

  Future<void> verifyOtp({
    required String identifier,
    required String phoneNumber,
    required String email,
    required String type,
    required String otp,
    bool isLogin = false,
    bool isForgot = false,
  }) async {
    isLoading = true;
    errorMessage = null;

    debugPrint(
      'VerifyOtpController flow forgot=$isForgot login=$isLogin type=$type',
    );

    try {
      final response = await _service.verifyOtp(
        identifier: identifier,
        phoneNumber: phoneNumber,
        email: email,
        type: type,
        otp: otp,
        isLogin: isLogin,
        isForgot: isForgot,
      );

      verifyOtpResponse = response;

      if (!response.success) {
        errorMessage = AuthApiException.userFacingMessage(
          response.message,
          fallback: 'Please enter the correct OTP.',
        );
        return;
      }

      final data = response.data;
      if (data == null) return;

      if (isForgot) {
        final resetToken = data.resetToken;
        if (resetToken != null && resetToken.isNotEmpty) {
          await TokenStorage.saveResetToken(resetToken);
          debugPrint('VerifyOtpController reset token saved');
        }
        return;
      }

      await AuthStateManager().onAuthSuccess(
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
        userId: data.userId,
      );
      ProfileIdentityService.instance.clearCachedLoggedInUserId();

      if (data.userId.trim().isNotEmpty) {
        ProfileIdentityService.instance.primeLoggedInUserId(data.userId);
      }

      debugPrint('VerifyOtpController tokens saved');
    } catch (e) {
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback: 'Please enter the correct OTP.',
      );
    } finally {
      isLoading = false;
    }
  }
}
