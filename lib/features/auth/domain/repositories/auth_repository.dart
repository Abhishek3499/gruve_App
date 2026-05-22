import 'package:gruve_app/features/auth/api/models/phone_login_model.dart';

import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  Future<EmailSignInResponse> login({
    required String identifier,
    required String password,
  });

  Future<SignupResponse> signup(SignupRequest request);

  Future<PhoneloginResponse> phoneLogin({required String phoneNumber});

  Future<VerifyOtpResponse> verifyOtp({
    required String identifier,
    required String email,
    required String phoneNumber,
    required String type,
    required String otp,
    bool isLogin,
    bool isForgot,
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
