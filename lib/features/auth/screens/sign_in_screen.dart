import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/features/auth/api/controllers/google_sign_in_controller.dart';
import 'package:gruve_app/features/auth/screens/complete_profile_screen.dart';
import 'package:gruve_app/features/auth/screens/phone_number_screen.dart';
import 'package:gruve_app/features/auth/widgets/auth_header.dart';
import 'package:gruve_app/features/auth/widgets/auth_divider.dart';
import 'package:gruve_app/features/auth/widgets/social_login_row.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/auth/core/auth_session_helper.dart';
import 'package:gruve_app/features/auth/screens/email_login_screen.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/features/auth/screens/signup_screen.dart';
import 'package:gruve_app/core/widgets/primary_button.dart';
import 'package:gruve_app/core/widgets/outline_button.dart';
import 'package:gruve_app/core/widgets/video_background.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleAuthController _googleController = GoogleAuthController();
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Warm up Google sign-in configuration asynchronously so it's ready when the button is clicked
    try {
      GoogleSignIn.instance.initialize(
        serverClientId: EnvironmentConfig.googleWebClientId,
      ).catchError((e) {
        AppLogger.d('Failed to warm up Google Sign In: $e');
      });
    } catch (e) {
      AppLogger.d('Failed to warm up Google Sign In: $e');
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    final success = await _googleController.signIn();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (!success) {
      final message = _googleController.errorMessage;
      if (message != null && message.trim().isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    final accessToken = _googleController.response?.data?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      AuthSessionHelper.connectSocket(accessToken);
    }

    final isNewUser = _googleController.needsProfileSetup;

    if (!isNewUser && mounted) {
      AuthSessionHelper.bootstrapAfterLogin(context, accessToken ?? '');
    }

    final nextScreen = isNewUser
        ? const CompleteProfileScreen()
        : const HomeScreen();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => nextScreen),
      (route) => false,
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
            padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
            child: Column(
              children: [
                const Spacer(),
                const AuthHeader(title: 'Sign  ', highlightedText: 'IN'),

                SizedBox(height: context.rh(32)),

                PrimaryButton(
                  text: 'Continue with Email',
                  onPressed: () {
                    _navigate(context, const EmailLoginScreen());
                  },
                ),

                SizedBox(height: context.rh(16)),

                OutlineButton(
                  text: 'Use phone number',
                  onPressed: () {
                    _navigate(context, const PhoneNumberScreen());
                  },
                ),

                SizedBox(height: context.rh(24)),

                const AuthDivider(),

                SizedBox(height: context.rh(24)),

                _isGoogleLoading
                    ? SizedBox(
                        width: context.rw(50),
                        height: context.rh(50),
                        child: Center(
                          child: SizedBox(
                            width: context.rw(24),
                            height: context.rh(24),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFBB86FC),
                            ),
                          ),
                        ),
                      )
                    : SocialLoginRow(onGooglePressed: _handleGoogleSignIn),
                const Spacer(),

                GestureDetector(
                  onTap: () {
                    _navigate(context, const SignupScreen());
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.rf(14),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Don\'t have an account?  ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: AppAssets.montserratfont,
                          ),
                        ),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: const Color(0xFFB86AD0),
                            fontWeight: FontWeight.w700,
                            fontSize: context.rf(14),
                            fontFamily: AppAssets.montserratfont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.rh(25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
