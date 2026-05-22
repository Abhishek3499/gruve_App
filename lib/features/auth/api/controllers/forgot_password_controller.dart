import 'package:flutter/material.dart';

import '../services/forgot_password_service.dart';

class ForgotPasswordController {
  final ForgotPasswordService _service = ForgotPasswordService();

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<String> sendEmail(String email) async {
    try {
      isLoading.value = true;

      final message = await _service.sendResetLink(email: email);
      return message;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
