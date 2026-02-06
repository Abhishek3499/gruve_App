import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth_flow.dart';
import 'package:gruve_app/screens/auth/screens/complete_profile_screen.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';

import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/widgets/inputs/neon_password_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.18),
                        Align(
                          alignment: AlignmentDirectional.topStart,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                fontFamily: AppAssets.syncopateFont,
                              ),
                              children: [
                                TextSpan(text: 'SIGN '),
                                TextSpan(
                                  text: 'UP',
                                  style: TextStyle(color: Color(0xFFB86AD0)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentGeometry.centerLeft,
                          child: const Text(
                            'Create Your Account',

                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Full Name',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'montserrat',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonTextField(
                          hintText: 'Enter your full name',
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonTextField(
                          hintText: 'Enter your email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonPasswordField(hintText: 'Create a strong password'),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Confirm Password',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonPasswordField(hintText: 'Confirm your password'),
                        const SizedBox(height: 30),
                        GetStartedButton(
                          text: 'SIGN UP',
                          onComplete: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtpScreen(
                                  authFlow: AuthFlow.signUp,
                                  title: 'Enter your Code',
                                  description:
                                      'Enter the 4-digit code sent to your email address.',
                                  buttonText: 'Continue',
                                  onVerified: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CompleteProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFFB86AD0),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
