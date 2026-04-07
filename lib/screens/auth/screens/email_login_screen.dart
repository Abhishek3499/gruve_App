import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/screens/auth/api/controllers/login_controller.dart';
import 'package:gruve_app/screens/auth/screens/forgot_password_screen.dart';
import 'package:gruve_app/screens/auth/screens/signup_screen.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/inputs/neon_password_field.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/widgets/video_background.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final EmailSignInController _controller = EmailSignInController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String? _emailApiError;
  String? _passwordApiError;
  String? _generalApiError;

  String? _validateEmail(String? value) {
    return SignupValidator.validateEmail(value ?? '');
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Enter your password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _clearApiErrors() {
    _emailApiError = null;
    _passwordApiError = null;
    _generalApiError = null;
  }

  void _applyLoginApiError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('email') ||
        lower.contains('user not found') ||
        lower.contains('account not found') ||
        lower.contains('no user')) {
      _emailApiError = SignupValidator.normalizeEmailNotFoundMessage(message);
      return;
    }

    if (lower.contains('password') ||
        lower.contains('credential') ||
        lower.contains('incorrect') ||
        lower.contains('invalid')) {
      _passwordApiError = message;
      return;
    }

    _generalApiError = message;
  }

  Future<bool> _handleLogin() async {
    setState(_clearApiErrors);

    if (_formKey.currentState?.validate() != true) {
      return false;
    }

    setState(() => isLoading = true);

    await _controller.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) {
      return false;
    }

    setState(() => isLoading = false);

    if (_controller.errorMessage != null) {
      setState(() {
        _applyLoginApiError(_controller.errorMessage!);
      });
      return false;
    }

    if (_controller.response?.success == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
        child: Stack(
          children: [
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
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.26),
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
                          NeonTextField(
                            hintText: 'Loisbecket@gmail.com',
                            prefixIcon: AppAssets.user2,
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            externalErrorText: _emailApiError,
                            onChanged: (_) {
                              if (_emailApiError != null ||
                                  _generalApiError != null) {
                                setState(() {
                                  _emailApiError = null;
                                  _generalApiError = null;
                                });
                              }
                            },
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_passwordFocus);
                            },
                            validator: _validateEmail,
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
                          NeonPasswordField(
                            hintText: 'Password',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.done,
                            externalErrorText: _passwordApiError,
                            onChanged: (_) {
                              if (_passwordApiError != null ||
                                  _generalApiError != null) {
                                setState(() {
                                  _passwordApiError = null;
                                  _generalApiError = null;
                                });
                              }
                            },
                            onFieldSubmitted: (_) => _handleLogin(),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 10),
                          if (_generalApiError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 6),
                              child: Text(
                                _generalApiError!,
                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
                              onComplete: _handleLogin,
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.14),
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
