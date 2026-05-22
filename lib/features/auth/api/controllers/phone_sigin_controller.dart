import 'package:flutter/material.dart';

import '../models/phone_login_model.dart';
import '../services/phone_login_services.dart';

class PhoneSignInController {
  final PhoneSiginServices _service = PhoneSiginServices();

  bool isLoading = false;
  String? errorMessage;
  PhoneloginResponse? response;

  Future<void> signIn({required String phoneNumber}) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn(phoneNumber: phoneNumber);
      response = res;

      debugPrint('Phone login success=${res.success}');
      if (!res.success) {
        errorMessage = res.message;
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Phone login controller error: $e');
    } finally {
      isLoading = false;
    }
  }
}
