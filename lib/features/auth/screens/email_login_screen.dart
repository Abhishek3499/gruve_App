import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/auth/api/controllers/login_controller.dart';
import 'package:gruve_app/features/auth/core/auth_session_helper.dart';
import 'package:gruve_app/features/auth/presentation/provider/auth_ui_provider.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:provider/provider.dart';

import 'package:gruve_app/features/auth/screens/forgot_password_screen.dart';

import 'package:gruve_app/features/auth/screens/signup_screen.dart'; // ✅ FIX 1: Missing import added

import 'package:gruve_app/core/widgets/get_started_button.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';

import 'package:gruve_app/core/widgets/video_background.dart';

import 'package:gruve_app/core/widgets/inputs/neon_text_field.dart';

import 'package:gruve_app/core/widgets/inputs/neon_password_field.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final EmailSignInController _controller = EmailSignInController();
  final GetStartedButtonController _loginButtonController =
      GetStartedButtonController();

  // Controllers & focus nodes
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();

  final FocusNode _passwordFocus = FocusNode();

  // Form key for backward compatibility
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _emailTouched = false;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetLogin();
    });
    _setupRealTimeValidation();
  }



  void _setupRealTimeValidation() {
    // Email field real-time validation

    _emailController.addListener(() {
      final error = SignupValidator.validateEmailRealTime(
        _emailController.text,
      );

      context.read<AuthUiProvider>().setValidationError('login_email', error);
    });

    // Password field real-time validation
    _passwordController.addListener(() {
      final error = _validatePasswordForLogin(_passwordController.text);
      context.read<AuthUiProvider>().setValidationError('login_password', error);
    });
  }

  String? _validatePasswordForLogin(String password) {
    if (password.trim().isEmpty) {
      return 'Please enter your password';
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
    if (mounted) {
      setState(() {
        _emailTouched = true;
        _passwordTouched = true;
      });
    }

    final authUi = context.read<AuthUiProvider>();
    if (authUi.isLoading(AuthLoadingKey.login)) return false;

    final emailError = SignupValidator.validateEmailRealTime(
      _emailController.text,
    );
    final passwordError = _validatePasswordForLogin(_passwordController.text);

    authUi.setErrors({
      'login_email': emailError,
      'login_password': passwordError,
    });

    // Check real-time validation errors instead of form validation
    if (emailError != null || passwordError != null) {
      // Show specific error if any
      String errorMessage =
          emailError ?? passwordError ?? 'Please fill all fields';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage)));
      return false;
    }

    authUi.setLoading(AuthLoadingKey.login, true);

    try {
      await _controller.signIn(
        identifier: _emailController.text.trim(),

        password: _passwordController.text.trim(),
      );
    } finally {
      authUi.setLoading(AuthLoadingKey.login, false);
    }

    if (!mounted) return false;

    //

    if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));

      return false;
    }

    if (_controller.response?.success == true) {
      if (!mounted) return false;

      final accessToken = _controller.response!.data!.accessToken;
      AuthSessionHelper.bootstrapAfterLogin(context, accessToken);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );

      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.login),
    );
    final emailErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('login_email'),
    );
    final passwordErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('login_password'),
    );
    final emailError = _emailTouched ? emailErrorRaw : null;
    final passwordError = _passwordTouched ? passwordErrorRaw : null;
    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: Stack(
          children: [
            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.rw(24)),

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
                          Text(
                            'Email',

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: context.rf(28),

                              fontWeight: FontWeight.w700,

                              letterSpacing: 1.0,

                              fontFamily: AppAssets.syncopateFont,
                            ),
                          ),

                          SizedBox(height: context.rh(12)),

                          Text(
                            'Please enter your valid email. We will send you a 4-digit code to verify your account.',

                            textAlign: TextAlign.center,

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: context.rf(16),

                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          SizedBox(height: context.rh(26)),

                          Align(
                            alignment: Alignment.centerLeft,

                            child: Text(
                              'Email',

                              style: TextStyle(
                                color: Colors.white70,

                                fontSize: context.rf(16),

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          SizedBox(height: context.rh(10)),

                          // ✅ FIX 8: Removed erroneous `const` — passing runtime controller
                          NeonTextField(
                            hintText: 'Enter your Email',

                            prefixIcon: AppAssets.user2,

                            controller: _emailController,

                            focusNode: _emailFocus,

                            keyboardType: TextInputType.emailAddress,

                            textInputAction: TextInputAction.next,

                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocus),
                            errorText: emailError,
                          ),

                          SizedBox(height: context.rh(20)),

                          Align(
                            alignment: Alignment.centerLeft,

                            child: Text(
                              'Password',

                              style: TextStyle(
                                color: Colors.white70,

                                fontSize: context.rf(16),

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          SizedBox(height: context.rh(10)),

                          // ✅ FIX 9: Removed erroneous `const` — passing runtime controller
                          NeonPasswordField(
                            hintText: 'Enter Your Password',

                            controller: _passwordController,

                            focusNode: _passwordFocus,

                            textInputAction: TextInputAction.done,

                            onFieldSubmitted: (_) =>
                                _loginButtonController.submit(),

                            errorText: passwordError,
                          ),

                          SizedBox(height: context.rh(10)),

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

                                  fontSize: context.rf(14),

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: context.rh(25)),

                          Align(
                            alignment: Alignment.center,

                            child: GetStartedButton(
                              controller: _loginButtonController,

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

                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white70,

                                    fontSize: context.rf(14),
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

                                        fontSize: context.rf(14),

                                        fontFamily: AppAssets.montserratfont,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: context.rh(24)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Back button
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: context.rw(24),
                  top: context.rh(25),
                ),

                child: BackButton(
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
