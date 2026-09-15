import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/verify_otp_controller.dart';

/// UI state for the OTP screen: the verify and resend loading flags.
/// Replaces the OTP-only slice that used to live in `AuthUiProvider`.
///
/// There is no debounced field-validation error or countdown/cooldown timer
/// here because the existing OTP flow has neither — OTP format is only
/// checked at submit time, and "Resend code" is only guarded by the resend
/// loading flag, not a timer.
class OtpUiState {
  const OtpUiState({this.isLoading = false, this.isResending = false});

  final bool isLoading;
  final bool isResending;
}

/// Owns the OTP screen's verify/resend loading state and delegates to
/// [VerifyotpController].
class OtpNotifier extends Notifier<OtpUiState> {
  late final VerifyotpController _controller;

  @override
  OtpUiState build() {
    _controller = VerifyotpController();
    return const OtpUiState();
  }

  /// Clears OTP state when the screen mounts, matching the previous
  /// `AuthUiProvider.resetOtp()`.
  void reset() {
    state = const OtpUiState();
  }

  Future<OtpVerificationResult> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    state = OtpUiState(isLoading: true, isResending: state.isResending);
    try {
      return await _controller.verifyOtp(identifier: identifier, otp: otp, purpose: purpose);
    } finally {
      state = OtpUiState(isLoading: false, isResending: state.isResending);
    }
  }

  Future<OtpResendResult> resendOtp({
    required String identifier,
    required String purpose,
  }) async {
    state = OtpUiState(isLoading: state.isLoading, isResending: true);
    try {
      return await _controller.resendOtp(identifier: identifier, purpose: purpose);
    } finally {
      state = OtpUiState(isLoading: state.isLoading, isResending: false);
    }
  }
}

final otpNotifierProvider = NotifierProvider<OtpNotifier, OtpUiState>(OtpNotifier.new);
