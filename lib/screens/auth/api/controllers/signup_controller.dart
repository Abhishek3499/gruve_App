import '../models/signup_request.dart';
import '../models/signup_response.dart';
import '../services/signup_service.dart';

class SignupController {
  bool isLoading = false;
  String? errorMessage;
  SignupResponse? signupResponse;

  final SignupService _service = SignupService();

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final request = SignupRequest(
        fullName: fullName,
        email: email,
        password: password,
      );

      signupResponse = await _service.signup(request);

      print("User ID: ${signupResponse?.data?.id}");
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
  }
}
