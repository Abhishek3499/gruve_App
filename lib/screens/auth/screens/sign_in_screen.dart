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

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ FIX
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
                    _navigate(context, const EmailLoginScreen());
                  },
                ),

                const SizedBox(height: 16),

                OutlineButton(
                  text: 'Use phone number',
                  onPressed: () {
                    _navigate(context, const PhoneNumberScreen());
                  },
                ),

                const SizedBox(height: 24),

                const AuthDivider(),

                const SizedBox(height: 24),

                const SocialLoginRow(),
                const Spacer(),

                GestureDetector(
                  onTap: () {
                    _navigate(context, const SignupScreen());
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
