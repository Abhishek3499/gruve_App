import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart' show TokenStorage;

import 'package:gruve_app/features/auth/data/dto/verify_otp_response.dart';
import 'package:gruve_app/features/auth/data/datasource/verify_otp_service.dart';

/// Verifies/resends an OTP and applies the resulting side effects (token
/// save, profile identity priming, reset-token save). Loading state is owned
/// by the OTP Riverpod notifier, not here.
class VerifyotpController {
  VerifyotpController({VerifyOtpService? service}) : _service = service ?? VerifyOtpService();

  final VerifyOtpService _service;

  Future<OtpVerificationResult> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    try {
      final response = await _service.verifyOtp(
        identifier: identifier,
        otp: otp,
        purpose: purpose,
      );

      if (!response.success) {
        return OtpVerificationResult.failure(
          AuthApiException.userFacingMessage(
            response.message,
            fallback: 'OTP does not match. Please enter the valid OTP sent to you.',
          ),
        );
      }

      final data = response.data;
      if (data != null) {
        if (purpose == OtpPurpose.resetPassword) {
          final resetToken = data.resetToken;
          if (resetToken != null && resetToken.isNotEmpty) {
            await TokenStorage.saveResetToken(resetToken);
          }
        } else {
          await AuthStateManager().onAuthSuccess(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            userId: data.userId,
          );
          ProfileIdentityService.instance.clearCachedLoggedInUserId();

          if (data.userId.trim().isNotEmpty) {
            ProfileIdentityService.instance.primeLoggedInUserId(data.userId);
          }
        }
      }

      return OtpVerificationResult.success(response);
    } catch (e) {
      return OtpVerificationResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback: 'OTP does not match. Please enter the valid OTP sent to you.',
        ),
      );
    }
  }

  Future<OtpResendResult> resendOtp({
    required String identifier,
    required String purpose,
  }) async {
    try {
      await _service.resendOtp(identifier: identifier, purpose: purpose);
      return const OtpResendResult.success();
    } catch (e) {
      return OtpResendResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback: 'Failed to resend OTP. Please try again.',
        ),
      );
    }
  }
}

class OtpVerificationResult {
  const OtpVerificationResult._({
    required this.isSuccess,
    this.response,
    this.errorMessage,
  });

  factory OtpVerificationResult.success(VerifyOtpResponse response) =>
      OtpVerificationResult._(isSuccess: true, response: response);

  factory OtpVerificationResult.failure(String message) =>
      OtpVerificationResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final VerifyOtpResponse? response;
  final String? errorMessage;
}

class OtpResendResult {
  const OtpResendResult._({required this.isSuccess, this.errorMessage});

  const OtpResendResult.success() : this._(isSuccess: true);

  factory OtpResendResult.failure(String message) =>
      OtpResendResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final String? errorMessage;
}
