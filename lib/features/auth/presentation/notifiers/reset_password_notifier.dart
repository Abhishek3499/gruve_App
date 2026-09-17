import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/reset_password_controller.dart';

/// UI state for the Reset Password screen: just the submit-loading flag.
/// Replaces the Reset-Password-only slice that used to live in
/// `AuthUiProvider`.
///
/// There is no field-validation error or debounce state here because the
/// existing screen never routed password/confirm-password errors through
/// `AuthUiProvider` — it always used plain local `setState`.
class ResetPasswordUiState {
  const ResetPasswordUiState({this.isLoading = false});

  final bool isLoading;
}

/// Owns the Reset Password screen's loading state and delegates to
/// [ResetPasswordController].
class ResetPasswordNotifier extends Notifier<ResetPasswordUiState> {
  late final ResetPasswordController _controller;

  @override
  ResetPasswordUiState build() {
    _controller = ResetPasswordController();
    return const ResetPasswordUiState();
  }

  /// Clears loading when the screen mounts, matching the previous
  /// `AuthUiProvider.resetResetPassword()`.
  void reset() {
    state = const ResetPasswordUiState();
  }

  Future<ResetPasswordResult> resetPassword({
    required String identifier,
    required String otp,
    required String password,
  }) async {
    state = const ResetPasswordUiState(isLoading: true);
    try {
      return await _controller.resetPassword(
        identifier: identifier,
        otp: otp,
        password: password,
      );
    } finally {
      state = const ResetPasswordUiState(isLoading: false);
    }
  }
}

final resetPasswordNotifierProvider =
    NotifierProvider<ResetPasswordNotifier, ResetPasswordUiState>(
      ResetPasswordNotifier.new,
    );
