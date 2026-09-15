import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/signup_controller.dart';

/// UI state for the Signup screen: submit-loading flag, the four debounced
/// field-validation errors, the email/phone contact-mode toggle, and gender
/// selection. Replaces the Signup-only slice that used to live in
/// `AuthUiProvider`.
class SignupUiState {
  const SignupUiState({
    this.isLoading = false,
    this.useEmail = true,
    this.selectedGender,
    this.genderTouched = false,
    this.nameError,
    this.identifierError,
    this.passwordError,
    this.confirmPasswordError,
  });

  final bool isLoading;
  final bool useEmail;
  final String? selectedGender;
  final bool genderTouched;
  final String? nameError;
  final String? identifierError;
  final String? passwordError;
  final String? confirmPasswordError;

  String? get genderError =>
      genderTouched && selectedGender == null ? 'Please select your gender' : null;
}

/// Owns Signup's loading/field-error/contact-mode/gender state and delegates
/// the actual signup call to [SignupController]. Field-validation errors are
/// debounced by 200ms, matching the previous
/// `AuthUiProvider.setValidationError` behavior.
class SignupNotifier extends Notifier<SignupUiState> {
  static const _validationDebounce = Duration(milliseconds: 200);

  final Map<String, Timer> _debounceTimers = {};
  late final SignupController _controller;

  @override
  SignupUiState build() {
    _controller = SignupController();
    ref.onDispose(() {
      for (final timer in _debounceTimers.values) {
        timer.cancel();
      }
    });
    return const SignupUiState();
  }

  void setNameError(String? error) => _setDebounced('name', error, (e) {
        if (state.nameError == e) return;
        state = SignupUiState(
          isLoading: state.isLoading,
          useEmail: state.useEmail,
          selectedGender: state.selectedGender,
          genderTouched: state.genderTouched,
          nameError: e,
          identifierError: state.identifierError,
          passwordError: state.passwordError,
          confirmPasswordError: state.confirmPasswordError,
        );
      });

  void setIdentifierError(String? error) => _setDebounced('identifier', error, (e) {
        if (state.identifierError == e) return;
        state = SignupUiState(
          isLoading: state.isLoading,
          useEmail: state.useEmail,
          selectedGender: state.selectedGender,
          genderTouched: state.genderTouched,
          nameError: state.nameError,
          identifierError: e,
          passwordError: state.passwordError,
          confirmPasswordError: state.confirmPasswordError,
        );
      });

  void setPasswordError(String? error) => _setDebounced('password', error, (e) {
        if (state.passwordError == e) return;
        state = SignupUiState(
          isLoading: state.isLoading,
          useEmail: state.useEmail,
          selectedGender: state.selectedGender,
          genderTouched: state.genderTouched,
          nameError: state.nameError,
          identifierError: state.identifierError,
          passwordError: e,
          confirmPasswordError: state.confirmPasswordError,
        );
      });

  void setConfirmPasswordError(String? error) =>
      _setDebounced('confirmPassword', error, (e) {
        if (state.confirmPasswordError == e) return;
        state = SignupUiState(
          isLoading: state.isLoading,
          useEmail: state.useEmail,
          selectedGender: state.selectedGender,
          genderTouched: state.genderTouched,
          nameError: state.nameError,
          identifierError: state.identifierError,
          passwordError: state.passwordError,
          confirmPasswordError: e,
        );
      });

  void _setDebounced(String key, String? error, void Function(String?) apply) {
    _debounceTimers[key]?.cancel();
    if (error == null) {
      apply(null);
      return;
    }
    _debounceTimers[key] = Timer(_validationDebounce, () => apply(error));
  }

  /// Sets all four field errors immediately, bypassing the debounce. Used
  /// right before submit, mirroring `AuthUiProvider.setErrors`.
  void setErrorsNow({
    String? nameError,
    String? identifierError,
    String? passwordError,
    String? confirmPasswordError,
  }) {
    for (final key in const ['name', 'identifier', 'password', 'confirmPassword']) {
      _debounceTimers.remove(key)?.cancel();
    }
    state = SignupUiState(
      isLoading: state.isLoading,
      useEmail: state.useEmail,
      selectedGender: state.selectedGender,
      genderTouched: state.genderTouched,
      nameError: nameError,
      identifierError: identifierError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
    );
  }

  /// Switches the email/phone contact mode and clears any identifier error
  /// (and pending debounce), matching `_setContactMode`'s intent in the
  /// screen. Unlike the previous `AuthUiProvider.setError` call this also
  /// cancels a pending debounce timer, closing a latent race where a
  /// stale validation result could reappear ~200ms after switching modes.
  void setContactMode(bool useEmail) {
    if (state.useEmail == useEmail) return;
    _debounceTimers.remove('identifier')?.cancel();
    state = SignupUiState(
      isLoading: state.isLoading,
      useEmail: useEmail,
      selectedGender: state.selectedGender,
      genderTouched: state.genderTouched,
      nameError: state.nameError,
      identifierError: null,
      passwordError: state.passwordError,
      confirmPasswordError: state.confirmPasswordError,
    );
  }

  void touchGender() {
    if (state.genderTouched) return;
    state = SignupUiState(
      isLoading: state.isLoading,
      useEmail: state.useEmail,
      selectedGender: state.selectedGender,
      genderTouched: true,
      nameError: state.nameError,
      identifierError: state.identifierError,
      passwordError: state.passwordError,
      confirmPasswordError: state.confirmPasswordError,
    );
  }

  void setGender(String? gender) {
    if (state.selectedGender == gender) return;
    state = SignupUiState(
      isLoading: state.isLoading,
      useEmail: state.useEmail,
      selectedGender: gender,
      genderTouched: state.genderTouched,
      nameError: state.nameError,
      identifierError: state.identifierError,
      passwordError: state.passwordError,
      confirmPasswordError: state.confirmPasswordError,
    );
  }

  /// Clears Signup's state when the screen mounts, matching the previous
  /// `AuthUiProvider.resetSignup()`.
  void reset() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    state = const SignupUiState();
  }

  Future<SignupResult> signup({
    String? fullName,
    String? identifier,
    String? password,
    String? gender,
  }) async {
    state = SignupUiState(
      isLoading: true,
      useEmail: state.useEmail,
      selectedGender: state.selectedGender,
      genderTouched: state.genderTouched,
      nameError: state.nameError,
      identifierError: state.identifierError,
      passwordError: state.passwordError,
      confirmPasswordError: state.confirmPasswordError,
    );
    try {
      return await _controller.signup(
        fullName: fullName,
        identifier: identifier,
        password: password,
        gender: gender,
      );
    } finally {
      state = SignupUiState(
        isLoading: false,
        useEmail: state.useEmail,
        selectedGender: state.selectedGender,
        genderTouched: state.genderTouched,
        nameError: state.nameError,
        identifierError: state.identifierError,
        passwordError: state.passwordError,
        confirmPasswordError: state.confirmPasswordError,
      );
    }
  }
}

final signupNotifierProvider = NotifierProvider<SignupNotifier, SignupUiState>(
  SignupNotifier.new,
);
