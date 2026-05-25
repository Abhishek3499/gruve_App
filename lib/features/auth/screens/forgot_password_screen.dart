import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/features/auth/api/services/forgot_password_service.dart';
import 'package:gruve_app/features/auth/presentation/provider/auth_ui_provider.dart';
import 'package:provider/provider.dart';

import 'package:gruve_app/features/auth/screens/otp_screen.dart';

import 'package:gruve_app/features/auth/screens/reset_password_screen.dart';

import 'package:gruve_app/core/widgets/get_started_button.dart';

import 'package:gruve_app/core/widgets/video_background.dart';

import 'package:gruve_app/core/widgets/inputs/neon_text_field.dart';

import '../validators/signup_validator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;

  final ForgotPasswordService _service = ForgotPasswordService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetForgotPassword();
    });

    _emailController = TextEditingController();

    _setupRealTimeValidation();
  }

  void _setupRealTimeValidation() {
    // Email field real-time validation

    _emailController.addListener(() {
      final error = SignupValidator.validateEmailRealTime(
        _emailController.text,
      );

      context.read<AuthUiProvider>().setError('forgot_email', error);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUi = context.watch<AuthUiProvider>();
    final isLoading = authUi.isLoading(AuthLoadingKey.forgotPassword);

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

                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              SignupValidator.validateEmailRealTime(
                                value ?? '',
                              ),
                          errorText: authUi.error('forgot_email'),
                        ),

                        const SizedBox(height: 40),

                        // ... baki imports same ...

                        // GetStartedButton ke andar onComplete ko replace karein:
                        GetStartedButton(
                          text: 'RESET PASSWORD',

                          isLoading: isLoading,

                          onComplete: () async {
                            final email = _emailController.text.trim();
                            if (!mounted) return false;
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);
                            final authUi = context.read<AuthUiProvider>();
                            final emailError =
                                SignupValidator.validateEmailRealTime(email);
                            authUi.setError('forgot_email', emailError);

                            if (emailError != null) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(emailError)),
                              );
                              return false;
                            }

                            // ✅ LOADER START 🔥
                            authUi.setLoading(
                              AuthLoadingKey.forgotPassword,
                              true,
                            );

                            try {
                              await _service.sendResetLink(email: email);
                              if (!mounted) return false;

                              // ✅ LOADER STOP

                              authUi.setLoading(
                                AuthLoadingKey.forgotPassword,
                                false,
                              );

                              if (!mounted) return false;
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => OtpScreen(
                                    identifier: email,

                                    type: "email",

                                    title: 'Reset Password',

                                    description:
                                        'Enter the code sent to your email address.',

                                    buttonText: 'Reset Password',

                                    isForgot: true,

                                    onVerifiedWithToken: (token) {
                                      if (!nav.mounted) return;
                                      nav.push(
                                        MaterialPageRoute(
                                          builder: (_) => ResetPasswordScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );

                              return true;
                            } catch (e) {
                              // ✅ LOADER STOP ON ERROR

                              if (!mounted) return false;
                              authUi.setLoading(
                                AuthLoadingKey.forgotPassword,
                                false,
                              );

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text("Error: ${e.toString()}"),
                                ),
                              );

                              return false;
                            }
                          },
                        ),
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
