import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/home_screen.dart';

import 'package:gruve_app/screens/auth/api/controllers/phone_sigin_controller.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';

import 'package:gruve_app/screens/auth/screens/signup_screen.dart';
import 'package:gruve_app/screens/auth/widgets/phone_number_header.dart';

import 'package:gruve_app/widgets/get_started_button.dart';

import 'package:gruve_app/widgets/inputs/phone_input_field.dart';

import 'package:gruve_app/widgets/video_background.dart';
import '../validators/phone_number_validator.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  late final TextEditingController _phoneController;

  final PhoneSignInController _controller = PhoneSignInController();

  bool isLoading = false;

  // Real-time validation state
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _setupRealTimeValidation();
  }

  void _setupRealTimeValidation() {
    // Phone field real-time validation

    _phoneController.addListener(() {
      final error = PhoneNumberValidator.validatePhoneRealTime(
        _phoneController.text,
      );

      if (error != _phoneError) {
        setState(() => _phoneError = error);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();

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
              /// BACK BUTTON
              Positioned(
                top: 4,

                left: 24,

                child: GestureDetector(
                  onTap: () => Navigator.pop(context),

                  child: Image.asset(AppAssets.back, height: 22, width: 22),
                ),
              ),

              /// MAIN CONTENT
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

                      /// TITLE
                      const PhoneNumberHeader(
                        title: 'phone ',
                        highlightedText: 'number',
                      ),

                      const SizedBox(height: 12),

                      /// DESCRIPTION
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

                      /// LABEL
                      const Text(
                        'Phone Number',

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 16,

                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// PHONE INPUT
                      PhoneInputField(controller: _phoneController),

                      const SizedBox(height: 36),

                      /// LOGIN BUTTON
                      Center(
                        child: GetStartedButton(
                          text: 'Login',

                          isLoading: isLoading,

                          onComplete: () async {
                            final phone = _phoneController.text.trim();

                            // Check real-time validation errors

                            if (_phoneError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_phoneError!)),
                              );

                              return false;
                            }

                            setState(() => isLoading = true);

                            await _controller.signIn(phone_number: phone);

                            setState(() => isLoading = false);

                            // ❌ Error case

                            if (_controller.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_controller.errorMessage!),
                                ),
                              );

                              return false;
                            }

                            // ✅ Success → Navigate to OTP

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => OtpScreen(
                                  identifier: phone,

                                  type: "phone",

                                  title: 'Enter your Code',

                                  description:
                                      'Enter the 4-digit code sent to your phone number.',

                                  buttonText: 'Continue',

                                  isLogin: true,

                                  onVerified: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,

                                      MaterialPageRoute(
                                        builder: (_) => const HomeScreen(),
                                      ),

                                      (route) => false,
                                    );
                                  },
                                ),
                              ),
                            );

                            return true;
                          },
                        ),
                      ),

                      const SizedBox(height: 90),

                      /// SIGNUP
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
            ],
          ),
        ),
      ),
    );
  }
}
