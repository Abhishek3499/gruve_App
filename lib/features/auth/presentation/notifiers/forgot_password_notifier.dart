import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/forgot_password_controller.dart';

/// UI state for the Forgot Password screen: submit-loading flag plus the
/// debounced email-validation error. Replaces the Forgot-Password-only
/// slice that used to live in `AuthUiProvider`.
class ForgotPasswordUiState {
  const ForgotPasswordUiState({this.isLoading = false, this.emailError});

  final bool isLoading;
  final String? emailError;
}

/// Owns Forgot Password's loading/field-error state and delegates the
/// reset-link request to [ForgotPasswordController]. Field-validation errors
/// are debounced by 200ms, matching the previous
/// `AuthUiProvider.setValidationError` behavior.
class ForgotPasswordNotifier extends Notifier<ForgotPasswordUiState> {
  static const _validationDebounce = Duration(milliseconds: 200);

  Timer? _debounceTimer;
  late final ForgotPasswordController _controller;

  @override
  ForgotPasswordUiState build() {
    _controller = ForgotPasswordController();
    ref.onDispose(() => _debounceTimer?.cancel());
    return const ForgotPasswordUiState();
  }

  void setEmailError(String? error) {
    _debounceTimer?.cancel();
    if (error == null) {
      _applyEmailError(null);
      return;
    }
    _debounceTimer = Timer(_validationDebounce, () => _applyEmailError(error));
  }

  /// Sets the email error immediately, bypassing the debounce. Used right
  /// before submit, mirroring `AuthUiProvider.setError`.
  void setEmailErrorNow(String? error) {
    _debounceTimer?.cancel();
    _applyEmailError(error);
  }

  void _applyEmailError(String? error) {
    if (state.emailError == error) return;
    state = ForgotPasswordUiState(
      isLoading: state.isLoading,
      emailError: error,
    );
  }

  /// Clears Forgot Password's state when the screen mounts, matching the
  /// previous `AuthUiProvider.resetForgotPassword()`.
  void reset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    state = const ForgotPasswordUiState();
  }

  Future<ForgotPasswordResult> sendResetLink(String identifier) async {
    state = ForgotPasswordUiState(
      isLoading: true,
      emailError: state.emailError,
    );
    try {
      return await _controller.sendResetLink(identifier);
    } finally {
      state = ForgotPasswordUiState(
        isLoading: false,
        emailError: state.emailError,
      );
    }
  }
}

final forgotPasswordNotifierProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordUiState>(
      ForgotPasswordNotifier.new,
    );
