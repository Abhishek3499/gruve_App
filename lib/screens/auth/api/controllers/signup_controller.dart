import 'package:flutter/material.dart' show debugPrint;

import '../models/signup_request.dart';
import '../models/signup_response.dart';
import '../services/signup_service.dart';

class SignupController {
  bool isLoading = false;
  String? errorMessage;
  SignupResponse? signupResponse;

  final SignupService _service = SignupService();
  Future<void> signup({
    String? fullName,
    String? identifier,
    String? password,
    String? gender,
  }) async {
    isLoading = true;
    errorMessage = null;

    debugPrint("🚀 Signup Start");
    debugPrint("Name: $fullName");
    debugPrint("Identifier: $identifier");

    try {
      final request = SignupRequest(
        fullName: fullName,
        identifier: identifier,
        password: password,
        gender: gender,
      );

      signupResponse = await _service.signup(request);

      debugPrint("✅ User ID: ${signupResponse?.data?.id}");
    } catch (e) {
      final rawMessage = e.toString();
      errorMessage = rawMessage.replaceFirst("Exception: ", "").trim();
      debugPrint("❌ Signup Error: $errorMessage");
    }

    isLoading = false;
  }
}
