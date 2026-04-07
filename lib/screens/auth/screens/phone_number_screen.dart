import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/screens/auth/api/controllers/phone_sigin_controller.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/screens/auth/screens/signup_screen.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/inputs/phone_input_field.dart';
import 'package:gruve_app/widgets/video_background.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  late final TextEditingController _phoneController;
  final PhoneSignInController _controller = PhoneSignInController();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String? _phoneApiError;
  String? _generalApiError;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      return 'Enter your phone number';
    }
    if (digitsOnly.length < 7) {
      return 'Enter valid phone number';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }
    return null;
  }

  void _clearApiErrors() {
    _phoneApiError = null;
    _generalApiError = null;
  }

  void _applyPhoneApiError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('phone') ||
        lower.contains('number') ||
        lower.contains('mobile') ||
        lower.contains('invalid') ||
        lower.contains('otp')) {
      _phoneApiError = message;
    } else {
      _generalApiError = message;
    }
  }

  Future<bool> _handlePhoneLogin() async {
    setState(_clearApiErrors);

    if (_formKey.currentState?.validate() != true) {
      return false;
    }

    final phone = _phoneController.text.trim();

    setState(() => isLoading = true);
    await _controller.signIn(phone_number: phone);

    if (!mounted) {
      return false;
    }

    setState(() => isLoading = false);

    if (_controller.errorMessage != null) {
      setState(() {
        _applyPhoneApiError(_controller.errorMessage!);
      });
      return false;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          identifier: phone,
          type: "phone",
          title: 'Enter your Code',
          description: 'Enter the 4-digit code sent to your phone number.',
          buttonText: 'Continue',
          isLogin: true,
          onVerified: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
    return true;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 24,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(AppAssets.back, height: 22, width: 22),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.26,
                        ),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              fontFamily: AppAssets.syncopateFont,
                            ),
                            children: [
                              TextSpan(text: 'Phone '),
                              TextSpan(
                                text: 'Number',
                                style: TextStyle(
                                  color: Color(0xFFB86AD0),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Please enter your valid number. we will send\n'
                          'you a 4- digit code to verify your account.',
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
                          focusNode: _phoneFocus,
                          validator: _validatePhone,
                          externalErrorText: _phoneApiError,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {
                            if (_phoneApiError != null ||
                                _generalApiError != null) {
                              setState(() {
                                _phoneApiError = null;
                                _generalApiError = null;
                              });
                            }
                          },
                          onFieldSubmitted: (_) => _handlePhoneLogin(),
                        ),
                        const SizedBox(height: 36),
                        const SizedBox(height: 36),
                        Center(
                          child: GetStartedButton(
                            text: 'Login',
                            isLoading: isLoading,
                            onComplete: _handlePhoneLogin,
                          ),
                        ),
                        if (_generalApiError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: Text(
                              _generalApiError!,
                              style: const TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
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
                                    text: "Sign Up",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
