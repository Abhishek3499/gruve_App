import '../models/login_model.dart';
import '../services/login_services.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class EmailSignInController {
  final EmailSignInService _service = EmailSignInService();

  bool isLoading = false;
  String? errorMessage;
  EmailSignInResponse? response;

  Future<void> signIn({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;

    try {
      final res = await _service.signIn(email: email, password: password);

      response = res;

      print("✅ SUCCESS: ${res.success}");
      print("📩 MESSAGE: ${res.message}");

      // ✅ TOKEN SAVE SAFE
      if (res.success && res.data != null) {
        final accessToken = res.data!.accessToken;
        final refreshToken = res.data!.refreshToken;

        print("🔑 ACCESS TOKEN: $accessToken");
        print("🔄 REFRESH TOKEN: $refreshToken");

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        print("✅ TOKENS SAVED SUCCESSFULLY");
      } else {
        errorMessage = res.message;
      }
    } catch (e) {
      errorMessage = e.toString();
      print("❌ CONTROLLER ERROR: $e");
    }

    isLoading = false;
  }
}
