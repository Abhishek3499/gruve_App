import 'package:flutter/material.dart';
import '../services/reset_password_service.dart';

class ResetPasswordController {
  final ResetPasswordService _service = ResetPasswordService();

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final response = await _service.resetPassword(
        token: token,
        password: password,
      );

      return response.message;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
