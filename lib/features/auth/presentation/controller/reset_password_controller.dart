import 'package:flutter/material.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/reset_password_service.dart';

class ResetPasswordController {
  final ResetPasswordService _service = ResetPasswordService();

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<String> resetPassword({
    required String identifier,
    required String otp,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final response = await _service.resetPassword(
        identifier: identifier,
        otp: otp,
        password: password,
      );

      return response.message;
    } catch (e) {
      return AuthApiException.userFacingMessage(
        e,
        fallback: 'Password could not be reset. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
