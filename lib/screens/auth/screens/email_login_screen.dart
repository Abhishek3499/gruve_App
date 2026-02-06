import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth_flow.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/screens/auth/screens/forgot_password_screen.dart';
import 'package:gruve_app/screens/home/home_screen.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/widgets/inputs/neon_password_field.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
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
            // ✅ BACK BUTTON (NOW WORKS)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 24, top: 8),
                    child: Icon(
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.26),
                        Align(
                          alignment: Alignment.topLeft,

                          child: const Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              fontFamily: AppAssets.syncopateFont,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Please enter your valid email. we will send you a 4- digit code to verify your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,

                            fontFamily: AppAssets.montserratfont,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        NeonTextField(hintText: 'Email address'),

                        const SizedBox(height: 20),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        NeonPasswordField(hintText: 'Password'),

                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF9544A7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

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
                                      'Enter the 4-digit code sent to your email address.',
                                  buttonText: 'Continue',
                                  onVerified: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HomeScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: constraints.maxHeight * 0.14),
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
