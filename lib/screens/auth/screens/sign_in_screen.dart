import 'package:flutter/material.dart';
import 'package:gruve_app/screens/auth/widgets/auth_header.dart';
import 'package:gruve_app/screens/auth/widgets/auth_divider.dart';
import 'package:gruve_app/screens/auth/widgets/social_login_row.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/screens/email_login_screen.dart';
import 'package:gruve_app/screens/auth/screens/phone_number_screen.dart';
import 'package:gruve_app/screens/auth/screens/signup_screen.dart';
import 'package:gruve_app/widgets/primary_button.dart';
import 'package:gruve_app/widgets/outline_button.dart';
import 'package:gruve_app/widgets/video_background.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                const AuthHeader(title: 'Sign  ', highlightedText: 'IN'),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Continue with Email',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmailLoginScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                OutlineButton(
                  text: 'Use phone number',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneNumberScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const AuthDivider(),

                const SizedBox(height: 24),

                const SocialLoginRow(),
                const Spacer(),

                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
