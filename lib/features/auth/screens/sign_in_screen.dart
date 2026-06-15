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
import 'package:gruve_app/features/auth/screens/email_login_screen.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';

import 'package:gruve_app/features/auth/screens/signup_screen.dart';
import 'package:gruve_app/core/widgets/primary_button.dart';
import 'package:gruve_app/core/widgets/outline_button.dart';
import 'package:gruve_app/core/widgets/video_background.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
      SocketService().connect(accessToken);
    }

    final isNewUser = _googleController.needsProfileSetup;

    if (!isNewUser) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final storyController = Provider.of<StoryController>(
        context,
        listen: false,
      );

      // Refresh application state in the background to keep login fast.
      Future<void>.delayed(Duration.zero, () async {
        try {
          AppLogger.d('🔄 [Google Login] 🔄 Refreshing providers in background...');
          await profileProvider.refreshProfile();
          AppLogger.d('👤 [Google Login] 👤 Profile data refreshed');
          storyController.reset();
          AppLogger.d('📖 [Google Login] 📖 Story data reset');
          AppLogger.d('✅ [Google Login] ✅ Background refresh completed');
        } catch (e, stackTrace) {
          AppLogger.d('❌ [Google Login] ❌ Background refresh failed: $e');
          AppLogger.d('$stackTrace');
        }
      });
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

                _isGoogleLoading
                    ? const SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
