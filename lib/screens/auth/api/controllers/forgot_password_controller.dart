import 'package:flutter/material.dart';

import '../services/forgot_password_service.dart';

class ForgotPasswordController {
  final ForgotPasswordService _service = ForgotPasswordService();
  Future<bool> forgotPassword(String email) async {
    try {
      debugPrint("📤 CALLING FORGOT PASSWORD API");

      await _service.sendResetLink(email: email);

      debugPrint("✅ FORGOT PASSWORD SUCCESS");

      return true;
    } catch (e) {
      debugPrint("❌ CONTROLLER ERROR: $e");
      return false;
    }
  }
}
