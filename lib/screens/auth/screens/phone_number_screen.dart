import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth_flow.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/screens/auth/screens/signup_screen.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.26,
                      ),

                      /// TITLE
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontFamily: AppAssets.syncopateFont,
                          ),
                          children: [
                            TextSpan(text: 'Phone'),
                            TextSpan(
                              text: ' Number',
                              style: TextStyle(
                                color: Color(0xFFB86AD0),
                                fontFamily: 'syncopate',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// DESCRIPTION
                      const Text(
                        'Please enter your valid number. we will send\n'
                        'you a 4- digit code to verify your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 26),

                      /// LABEL
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phone Number',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// INPUT FIELD
                      const NeonTextField(hintText: 'Phone number'),

                      const SizedBox(height: 36),

                      /// LOGIN BUTTON
                      GetStartedButton(
                        text: 'Login',
                        onComplete: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtpScreen(
                                authFlow: AuthFlow.signIn,
                                title: 'Enter your Code',
                                description:
                                    'Enter the 4-digit code sent to your phone number.',
                                buttonText: 'Verify',
                                onVerified: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HomeScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 90),

                      /// SIGNUP
                      GestureDetector(
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
                                text: 'Don\'t have an account?  ',
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
