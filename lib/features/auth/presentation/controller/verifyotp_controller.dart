import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart' show TokenStorage;

import 'package:gruve_app/features/auth/data/dto/verify_otp_response.dart';
import 'package:gruve_app/features/auth/data/datasource/verify_otp_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VerifyotpController {
  final VerifyOtpService _service = VerifyOtpService();

  bool isLoading = false;
  String? errorMessage;
  VerifyOtpResponse? verifyOtpResponse;

  Future<void> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    isLoading = true;
    errorMessage = null;

    AppLogger.d('VerifyOtpController purpose=$purpose');

    try {
      final response = await _service.verifyOtp(
        identifier: identifier,
        otp: otp,
        purpose: purpose,
      );

      verifyOtpResponse = response;

      if (!response.success) {
        errorMessage = AuthApiException.userFacingMessage(
          response.message,
          fallback: 'OTP does not match. Please enter the valid OTP sent to you.',
        );
        return;
      }

      final data = response.data;
      if (data == null) return;

      if (purpose == OtpPurpose.resetPassword) {
        final resetToken = data.resetToken;
        if (resetToken != null && resetToken.isNotEmpty) {
          await TokenStorage.saveResetToken(resetToken);
          AppLogger.d('VerifyOtpController reset token saved');
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

      AppLogger.d('VerifyOtpController tokens saved');
    } catch (e) {
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback: 'OTP does not match. Please enter the valid OTP sent to you.',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<bool> resendOtp({
    required String identifier,
    required String purpose,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      await _service.resendOtp(
        identifier: identifier,
        purpose: purpose,
      );
      return true;
    } catch (e) {
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback: 'Failed to resend OTP. Please try again.',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }
}
