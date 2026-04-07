import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/api/services/forgot_password_service.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/screens/auth/screens/reset_password_screen.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/widgets/video_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  late final FocusNode _emailFocus;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ForgotPasswordService _service = ForgotPasswordService();

  bool isLoading = false;
  String? _emailApiError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String _extractDisplayMessage(Object error) {
    final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
    return SignupValidator.normalizeEmailNotFoundMessage(rawMessage);
  }

  Future<bool> _handleResetPassword() async {
    setState(() => _emailApiError = null);

    if (_formKey.currentState?.validate() != true) {
      return false;
    }

    final email = _emailController.text.trim();
    setState(() => isLoading = true);

    try {
      await _service.sendResetLink(email: email);

      if (!mounted) {
        return false;
      }

      setState(() => isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            identifier: email,
            type: "email",
            title: 'Reset Password',
            description: 'Enter the code sent to your email address.',
            buttonText: 'Reset Password',
            isForgot: true,
            onVerifiedWithToken: (token) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResetPasswordScreen(),
                ),
              );
            },
          ),
        ),
      );

      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        isLoading = false;
        _emailApiError = _extractDisplayMessage(error);
      });

      return false;
    }
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
                padding: const EdgeInsets.only(left: 16, top: 10),
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.18),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppAssets.syncopateFont,
                                ),
                                children: const [
                                  TextSpan(text: 'Forgot '),
                                  TextSpan(
                                    text: 'Password ',
                                    style: TextStyle(color: Color(0xFFB86AD0)),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Enter your email address and we will send\nyou a code to reset your password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email Address',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          NeonTextField(
                            controller: _emailController,
                            hintText: 'Enter your email address',
                            prefixIcon: AppAssets.user2,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            externalErrorText: _emailApiError,
                            onChanged: (_) {
                              if (_emailApiError != null) {
                                setState(() => _emailApiError = null);
                              }
                            },
                            onFieldSubmitted: (_) {
                              _handleResetPassword();
                            },
                            validator: (value) {
                              return SignupValidator.validateEmail(value ?? '');
                            },
                          ),
                          const SizedBox(height: 40),
                          GetStartedButton(
                            text: 'RESET PASSWORD',
                            isLoading: isLoading,
                            onComplete: _handleResetPassword,
                          ),
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
