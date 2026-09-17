import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/phone_login_controller.dart';

/// UI state for the Phone Login screen: submit-loading flag plus the
/// debounced phone-validation error. Replaces the Phone-Login-only slice
/// that used to live in `AuthUiProvider`.
class PhoneLoginUiState {
  const PhoneLoginUiState({this.isLoading = false, this.phoneError});

  final bool isLoading;
  final String? phoneError;
}

/// Owns Phone Login's loading/field-error state and delegates the OTP
/// request to [PhoneSignInController]. Field-validation errors are debounced
/// by 200ms, matching the previous `AuthUiProvider.setValidationError`
/// behavior.
class PhoneLoginNotifier extends Notifier<PhoneLoginUiState> {
  static const _validationDebounce = Duration(milliseconds: 200);

  Timer? _debounceTimer;
  late final PhoneSignInController _controller;

  @override
  PhoneLoginUiState build() {
    _controller = PhoneSignInController();
    ref.onDispose(() => _debounceTimer?.cancel());
    return const PhoneLoginUiState();
  }

  void setPhoneError(String? error) {
    _debounceTimer?.cancel();
    if (error == null) {
      _applyPhoneError(null);
      return;
    }
    _debounceTimer = Timer(_validationDebounce, () => _applyPhoneError(error));
  }

  /// Sets the phone error immediately, bypassing the debounce. Used right
  /// before submit, mirroring `AuthUiProvider.setError`.
  void setPhoneErrorNow(String? error) {
    _debounceTimer?.cancel();
    _applyPhoneError(error);
  }

  void _applyPhoneError(String? error) {
    if (state.phoneError == error) return;
    state = PhoneLoginUiState(isLoading: state.isLoading, phoneError: error);
  }

  /// Clears Phone Login's state when the screen mounts, matching the
  /// previous `AuthUiProvider.resetPhoneLogin()`.
  void reset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    state = const PhoneLoginUiState();
  }

  Future<PhoneLoginResult> requestOtp({required String phoneNumber}) async {
    state = PhoneLoginUiState(isLoading: true, phoneError: state.phoneError);
    try {
      return await _controller.requestOtp(phoneNumber: phoneNumber);
    } finally {
      state = PhoneLoginUiState(isLoading: false, phoneError: state.phoneError);
    }
  }
}

final phoneLoginNotifierProvider =
    NotifierProvider<PhoneLoginNotifier, PhoneLoginUiState>(
      PhoneLoginNotifier.new,
    );
