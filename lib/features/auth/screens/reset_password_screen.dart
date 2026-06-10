import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/features/auth/api/controllers/reset_password_controller.dart';

import 'package:gruve_app/features/auth/token_storage.dart';

import 'package:gruve_app/core/widgets/get_started_button.dart';

import 'package:gruve_app/core/widgets/video_background.dart';

import 'package:gruve_app/core/widgets/inputs/neon_password_field.dart';

import 'package:gruve_app/features/auth/screens/email_login_screen.dart';
import 'package:gruve_app/features/auth/presentation/provider/auth_ui_provider.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String identifier;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ResetPasswordController _controller = ResetPasswordController();
  final GetStartedButtonController _resetButtonController =
      GetStartedButtonController();

  late final TextEditingController _newPasswordController;

  late final TextEditingController _confirmPasswordController;
  late final FocusNode _confirmPasswordFocus;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetResetPassword();
    });

    _newPasswordController = TextEditingController();

    _confirmPasswordController = TextEditingController();
    _confirmPasswordFocus = FocusNode();
    _newPasswordController.addListener(_validatePasswordsAfterFirstError);
    _confirmPasswordController.addListener(_validatePasswordsAfterFirstError);
  }

  void _validatePasswordsAfterFirstError() {
    if (_passwordError == null && _confirmPasswordError == null) return;
    _validatePasswords();
  }

  bool _validatePasswords() {
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final passwordError = SignupValidator.validatePasswordRealTime(password);
    final confirmPasswordError =
        SignupValidator.validateConfirmPasswordRealTime(
          password,
          confirmPassword,
        );

    setState(() {
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    return passwordError == null && confirmPasswordError == null;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();

    _confirmPasswordController.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthUiProvider>().isLoading(
      AuthLoadingKey.resetPassword,
    );

    return Scaffold(
      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 9),

                child: Align(
                  alignment: Alignment.topLeft,

                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),

                    child: Image.asset(AppAssets.back, height: 22, width: 22),
                  ),
                ),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        SizedBox(height: constraints.maxHeight * 0.18),

                        RichText(
                          textAlign: TextAlign.start,

                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 26,

                              fontWeight: FontWeight.w700,

                              fontFamily: AppAssets.syncopateFont,
                            ),

                            children: [
                              TextSpan(text: 'Reset '),

                              TextSpan(
                                text: 'Password',

                                style: TextStyle(color: Color(0xFFB86AD0)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Create a new password for your account.\nMake sure it\'s strong and secure.',

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: Colors.white,

                            fontSize: 16,

                            fontWeight: FontWeight(400),
                          ),
                        ),

                        const SizedBox(height: 40),

                        const Align(
                          alignment: Alignment.centerLeft,

                          child: Text(
                            'Password',

                            style: TextStyle(
                              color: Color(0xFFFFFFFF),

                              fontSize: 16,

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        NeonPasswordField(
                          hintText: 'Enter Your Password',

                          controller: _newPasswordController,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _confirmPasswordFocus.requestFocus(),
                          errorText: _passwordError,
                        ),

                        const SizedBox(height: 20),

                        const Align(
                          alignment: Alignment.centerLeft,

                          child: Text(
                            'Confirm Password',

                            style: TextStyle(
                              color: Color(0xFFFFFFFF),

                              fontSize: 16,

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        NeonPasswordField(
                          hintText: 'Confirm Your Password',

                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _resetButtonController.submit(),
                          errorText: _confirmPasswordError,
                        ),

                        const SizedBox(height: 40),

                        Align(
                          alignment: AlignmentGeometry.center,

                          child: GetStartedButton(
                            controller: _resetButtonController,

                            text: 'Reset ',

                            isLoading: isLoading,

                            onComplete: () async {
                              final authUi = context.read<AuthUiProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(context);
                              final password = _newPasswordController.text
                                  .trim();
                              if (authUi.isLoading(
                                AuthLoadingKey.resetPassword,
                              )) {
                                return false;
                              }

                              if (!_validatePasswords()) {
                                messenger
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _passwordError ??
                                            _confirmPasswordError ??
                                            'Please fill in all fields',
                                      ),

                                      backgroundColor: Colors.red,
                                    ),
                                  );

                                return false;
                              }

                              authUi.setLoading(
                                AuthLoadingKey.resetPassword,
                                true,
                              );

                              // 🔥 CALL API

                              late final String message;
                              try {
                                message = await _controller.resetPassword(
                                  identifier: widget.identifier,
                                  otp: widget.otp,
                                  password: password,
                                );
                              } finally {
                                authUi.setLoading(
                                  AuthLoadingKey.resetPassword,
                                  false,
                                );
                              }

                              if (!mounted) return false;

                              if (message.toLowerCase().contains("success")) {
                                // ✅ CLEAR TOKEN AFTER SUCCESS

                                await TokenStorage.clearResetToken();

                                if (!mounted) return false;

                                messenger
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );

                                if (!nav.mounted) return false;

                                nav.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const EmailLoginScreen(),
                                  ),

                                  (route) => false,
                                );

                                return true;
                              } else {
                                if (!mounted) return false;

                                messenger
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(message),

                                      backgroundColor: Colors.red,
                                    ),
                                  );

                                return false;
                              }
                            },
                          ),
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
