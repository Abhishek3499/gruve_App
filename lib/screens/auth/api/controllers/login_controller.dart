import 'package:flutter/material.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';

import '../models/login_model.dart';
import '../services/login_services.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class EmailSignInController {
  final EmailSignInService _service = EmailSignInService();

  bool isLoading = false;
  String? errorMessage;
  EmailSignInResponse? response;

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn(
        identifier: identifier,
        password: password,
      );

      response = res;

      debugPrint("✅ SUCCESS: ${res.success}");
      debugPrint("📩 MESSAGE: ${res.message}");

      // ✅ TOKEN SAVE SAFE
      if (res.success && res.data != null) {
        final accessToken = res.data!.accessToken;
        final refreshToken = res.data!.refreshToken;

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        ProfileIdentityService.instance.clearCachedLoggedInUserId();

        if (res.data!.userId.trim().isNotEmpty) {
          await TokenStorage.saveCurrentUserId(res.data!.userId);
          ProfileIdentityService.instance.primeLoggedInUserId(res.data!.userId);
        }

        debugPrint("✅ TOKENS SAVED SUCCESSFULLY");
      } else {
        errorMessage = res.message;
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ CONTROLLER ERROR: $e");
    }

    isLoading = false;
  }
}
