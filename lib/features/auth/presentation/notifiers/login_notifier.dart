import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/login_controller.dart';

/// UI state for the Email Login screen: submit-loading flag plus the two
/// debounced field-validation errors. Replaces the Login-only slice that
/// used to live in `AuthUiProvider`.
class LoginUiState {
  const LoginUiState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
  });

  final bool isLoading;
  final String? emailError;
  final String? passwordError;
}

/// Owns Login's loading/field-error state and delegates the actual sign-in
/// call to [LoginController]. Field-validation errors are debounced by 200ms,
/// matching the previous `AuthUiProvider.setValidationError` behavior.
class LoginNotifier extends Notifier<LoginUiState> {
  static const _validationDebounce = Duration(milliseconds: 200);

  final Map<String, Timer> _debounceTimers = {};
  late final LoginController _controller;

  @override
  LoginUiState build() {
    _controller = LoginController();
    ref.onDispose(() {
      for (final timer in _debounceTimers.values) {
        timer.cancel();
      }
    });
    return const LoginUiState();
  }

  void setEmailError(String? error) {
    _debounceTimers['email']?.cancel();
    if (error == null) {
      _applyEmailError(null);
      return;
    }
    _debounceTimers['email'] = Timer(
      _validationDebounce,
      () => _applyEmailError(error),
    );
  }

  void setPasswordError(String? error) {
    _debounceTimers['password']?.cancel();
    if (error == null) {
      _applyPasswordError(null);
      return;
    }
    _debounceTimers['password'] = Timer(
      _validationDebounce,
      () => _applyPasswordError(error),
    );
  }

  /// Sets both field errors immediately, bypassing the debounce. Used right
  /// before submit, mirroring `AuthUiProvider.setErrors`.
  void setErrorsNow({String? emailError, String? passwordError}) {
    _debounceTimers.remove('email')?.cancel();
    _debounceTimers.remove('password')?.cancel();
    if (state.emailError == emailError && state.passwordError == passwordError) {
      return;
    }
    state = LoginUiState(
      isLoading: state.isLoading,
      emailError: emailError,
      passwordError: passwordError,
    );
  }

  void _applyEmailError(String? error) {
    if (state.emailError == error) return;
    state = LoginUiState(
      isLoading: state.isLoading,
      emailError: error,
      passwordError: state.passwordError,
    );
  }

  void _applyPasswordError(String? error) {
    if (state.passwordError == error) return;
    state = LoginUiState(
      isLoading: state.isLoading,
      emailError: state.emailError,
      passwordError: error,
    );
  }

  /// Clears Login's state when the screen mounts, matching the previous
  /// `AuthUiProvider.resetLogin()`.
  void reset() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    state = const LoginUiState();
  }

  Future<LoginResult> signIn({
    required String identifier,
    required String password,
  }) async {
    state = LoginUiState(
      isLoading: true,
      emailError: state.emailError,
      passwordError: state.passwordError,
    );
    try {
      return await _controller.signIn(identifier: identifier, password: password);
    } finally {
      state = LoginUiState(
        isLoading: false,
        emailError: state.emailError,
        passwordError: state.passwordError,
      );
    }
  }
}

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginUiState>(
  LoginNotifier.new,
);
