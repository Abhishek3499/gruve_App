import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';

import 'package:gruve_app/screens/auth/api/controllers/login_controller.dart';

import 'package:gruve_app/screens/auth/screens/forgot_password_screen.dart';

import 'package:gruve_app/screens/auth/screens/signup_screen.dart'; // ✅ FIX 1: Missing import added

import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';

import 'package:gruve_app/widgets/video_background.dart';

import 'package:gruve_app/widgets/inputs/neon_text_field.dart';

import 'package:gruve_app/widgets/inputs/neon_password_field.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final EmailSignInController _controller = EmailSignInController();

  bool isLoading = false;

  // Controllers & focus nodes
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();

  final FocusNode _passwordFocus = FocusNode();

  // Real-time validation state
  String? _emailError;
  String? _passwordError;

  // Form key for backward compatibility
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _setupRealTimeValidation();
  }

  void _setupRealTimeValidation() {
    // Email field real-time validation

    _emailController.addListener(() {
      final error = SignupValidator.validateEmailRealTime(
        _emailController.text,
      );

      if (error != _emailError) {
        setState(() => _emailError = error);
      }
    });

    // Password field real-time validation
    _passwordController.addListener(() {
      final error = _validatePasswordForLogin(_passwordController.text);
      if (error != _passwordError) {
        setState(() => _passwordError = error);
      }
    });
  }

  String? _validatePasswordForLogin(String password) {
    if (password.trim().isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  @override
  void dispose() {
    //

    _emailController.dispose();

    _passwordController.dispose();

    _emailFocus.dispose();

    _passwordFocus.dispose();

    super.dispose();
  }

  //

  Future<bool> _handleLogin() async {
    final emailError = SignupValidator.validateEmailRealTime(
      _emailController.text,
    );
    final passwordError = _validatePasswordForLogin(_passwordController.text);

    if (emailError != _emailError || passwordError != _passwordError) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
    }

    // Check real-time validation errors instead of form validation
    if (_emailError != null || _passwordError != null) {
      // Show specific error if any
      String errorMessage =
          _emailError ?? _passwordError ?? 'Please fill all fields';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return false;
    }

    setState(() => isLoading = true);

    await _controller.signIn(
      identifier: _emailController.text.trim(),

      password: _passwordController.text.trim(),
    );

    if (!mounted) return false;

    setState(() => isLoading = false);

    //

    if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));

      return false;
    }

    // ✅ SUCCESS CASE

    if (_controller.response?.success == true) {
      debugPrint("LOGIN SUCCESS -> GO TO HOME");

      if (!mounted) return false;

      // Refresh providers to fetch fresh data for new user
      try {
        debugPrint('🔄 [Login] Refreshing providers for fresh data...');
        
        // Refresh profile data
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.refreshProfile();
        
        // Refresh story data
        final storyController = Provider.of<StoryController>(context, listen: false);
        storyController.reset(); // Clear any cached story data
        
        debugPrint('✅ [Login] Providers refreshed successfully');
      } catch (e) {
        debugPrint('❌ [Login] Error refreshing providers: $e');
        // Continue navigation even if provider refresh fails
      }

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

      return true; // ✅ ADD THIS
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: Stack(
          children: [
            // Back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 8),

                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  onTap: () => Navigator.pop(context),

                  child: Image.asset(AppAssets.back, height: 25, width: 25),
                ),
              ),
            ),

            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: Form(
                    // ✅ FIX 6: Wrapped in Form for proper validation
                    key: _formKey,

                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          SizedBox(height: constraints.maxHeight * 0.26),

                          // ✅ FIX 7: Removed stray Align wrapper that had syntax error
                          const Text(
                            'Email',

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 28,

                              fontWeight: FontWeight.w700,

                              letterSpacing: 1.0,

                              fontFamily: AppAssets.syncopateFont,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Please enter your valid email. We will send you a 4-digit code to verify your account.',

                            textAlign: TextAlign.center,

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 16,

                              fontWeight: FontWeight.w400,
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

                          // ✅ FIX 8: Removed erroneous `const` — passing runtime controller
                          NeonTextField(
                            hintText: 'Loisbecket@gmail.com',

                            prefixIcon: AppAssets.user2,

                            controller: _emailController,

                            focusNode: _emailFocus,

                            keyboardType: TextInputType.emailAddress,

                            textInputAction: TextInputAction.next,

                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocus),

                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }

                              final emailRegex = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );

                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Enter a valid email address';
                              }

                              return null;
                            },
                          ),

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

                          // ✅ FIX 9: Removed erroneous `const` — passing runtime controller
                          NeonPasswordField(
                            hintText: 'Password',

                            controller: _passwordController,

                            focusNode: _passwordFocus,

                            textInputAction: TextInputAction.done,

                            onFieldSubmitted: (_) => _handleLogin(),

                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Password is required';
                              }

                              return null;
                            },
                          ),

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

                            child: const Align(
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

                          Align(
                            alignment: Alignment.center,

                            child: GetStartedButton(
                              text: 'Login',

                              isLoading: isLoading,

                              onComplete:
                                  _handleLogin, // ✅ FIX 10: Uses validated handler
                            ),
                          ),

                          SizedBox(height: constraints.maxHeight * 0.14),

                          // ✅ FIX 11: THE MAIN BUG — this widget was OUTSIDE Column's

                          // children list, causing a compile error. Moved inside correctly.
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,

                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },

                            child: Align(
                              alignment: Alignment.center,

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

                          const SizedBox(height: 24),
                        ],
                      ),
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
