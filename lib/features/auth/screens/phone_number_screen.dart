import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/widgets/get_started_button.dart';
import 'package:gruve_app/core/widgets/inputs/phone_input_field.dart';
import 'package:gruve_app/core/widgets/video_background.dart';
import 'package:gruve_app/features/auth/api/controllers/phone_signin_controller.dart';
import 'package:gruve_app/features/auth/presentation/provider/auth_ui_provider.dart';
import 'package:gruve_app/features/auth/screens/otp_screen.dart';
import 'package:gruve_app/features/auth/screens/signup_screen.dart';
import 'package:gruve_app/features/auth/widgets/phone_number_header.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:provider/provider.dart';

import '../validators/phone_number_validator.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  late final TextEditingController _phoneController;
  final FocusNode _phoneFocus = FocusNode();
  bool _phoneTouched = false;

  final PhoneSignInController _controller = PhoneSignInController();
  final GetStartedButtonController _phoneButtonController =
      GetStartedButtonController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetPhoneLogin();
    });
    _phoneController = TextEditingController();
    _setupRealTimeValidation();
  }

  void _setupRealTimeValidation() {
    _phoneController.addListener(() {
      final error = PhoneNumberValidator.validatePhoneRealTime(
        _phoneController.text,
      );

      context.read<AuthUiProvider>().setValidationError('phone_login_phone', error);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();

    super.dispose();
  }

  Future<bool> _handleLogin() async {
    if (mounted) {
      setState(() {
        _phoneTouched = true;
      });
    }

    final phone = _phoneController.text.trim();
    final phoneError = PhoneNumberValidator.validatePhoneRealTime(phone);

    context.read<AuthUiProvider>().setError('phone_login_phone', phoneError);

    if (phoneError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(phoneError)));

      return false;
    }

    final authUi = context.read<AuthUiProvider>();
    if (authUi.isLoading(AuthLoadingKey.phoneLogin)) {
      return false;
    }
    authUi.setLoading(AuthLoadingKey.phoneLogin, true);

    try {
      await _controller.requestOtp(phoneNumber: phone);
    } finally {
      authUi.setLoading(AuthLoadingKey.phoneLogin, false);
    }

    if (!mounted) return false;

    if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));

      return false;
    }

    if (_controller.response?.success != true) {
      return false;
    }

    if (!context.mounted) return false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          identifier: phone,
          type: 'phone',
          title: 'Enter your Code',
          description: 'Enter the 4-digit code sent to your phone number.',
          buttonText: 'Continue',
          isLogin: true,
          onVerified: () {
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.phoneLogin),
    );
    final phoneErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('phone_login_phone'),
    );
    final phoneError = _phoneTouched ? phoneErrorRaw : null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.26,
                      ),
                      const PhoneNumberHeader(
                        title: 'phone ',
                        highlightedText: 'number',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Please enter your valid number. We will send\n'
                        'you a 4-digit code to verify your account.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PhoneInputField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.done,
                        focusNode: _phoneFocus,
                        onFieldSubmitted: (_) =>
                            _phoneButtonController.submit(),
                        errorText: phoneError,
                      ),
                      const SizedBox(height: 36),
                      Center(
                        child: GetStartedButton(
                          controller: _phoneButtonController,
                          text: 'Login',
                          isLoading: isLoading,
                          onComplete: _handleLogin,
                        ),
                      ),
                      const SizedBox(height: 90),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Don't have an account?  ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppAssets.montserratfont,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFFB86AD0),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: AppAssets.montserratfont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 24,
                child: BackButton(
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
