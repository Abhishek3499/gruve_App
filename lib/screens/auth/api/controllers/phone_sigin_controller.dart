import 'package:flutter/material.dart';

import '../models/phone_login_model.dart';
import '../services/phone_login_services.dart';
// ❌ removed token_storage import

class PhoneSignInController {
  final PhoneSiginServices _service = PhoneSiginServices();

  bool isLoading = false;
  String? errorMessage;
  PhoneloginResponse? response;

  Future<void> signIn({required String phone_number}) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn(phone_number: phone_number);

      response = res;

      debugPrint("✅ SUCCESS: ${res.success}");
      debugPrint("📩 MESSAGE: ${res.message}");

      // ❌ TOKEN STORAGE REMOVED
      if (!res.success) {
        errorMessage = res.message;
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ CONTROLLER ERROR: $e");
    }

    isLoading = false;
  }
}
