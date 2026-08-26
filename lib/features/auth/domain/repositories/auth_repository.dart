import 'package:gruve_app/features/auth/data/models/auth_models.dart';

abstract class AuthRepository {
  Future<EmailSignInResponse> login({
    required String identifier,
    required String password,
  });

  Future<SignupResponse> signup(SignupRequest request);

  Future<VerifyOtpResponse> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  });

  Future<String> forgotPassword({required String email});

  Future<ResetPasswordResponse> resetPassword({
    required String token,
    required String password,
  });

  Future<CompleteProfileResponse> completeProfile({
    required CompleteProfileRequest request,
    String? file,
  });
}
