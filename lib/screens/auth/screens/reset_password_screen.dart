import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/api/controllers/reset_password_controller.dart';
import 'package:gruve_app/screens/auth/screens/email_login_screen.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/inputs/neon_password_field.dart';
import 'package:gruve_app/widgets/video_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ResetPasswordController _controller = ResetPasswordController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final FocusNode _newPasswordFocus;
  late final FocusNode _confirmPasswordFocus;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _newPasswordFocus = FocusNode();
    _confirmPasswordFocus = FocusNode();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<bool> _handleResetPassword() async {
    if (_formKey.currentState?.validate() != true) {
      return false;
    }

    final token = await TokenStorage.getResetToken();
    if (token == null) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final message = await _controller.resetPassword(
      token: token,
      password: _newPasswordController.text.trim(),
    );

    if (!mounted) {
      return false;
    }

    if (message.toLowerCase().contains("success")) {
      await TokenStorage.clearResetToken();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
        (route) => false,
      );

      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                              fontWeight: FontWeight.w400,
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
                            hintText: 'Enter new password',
                            controller: _newPasswordController,
                            focusNode: _newPasswordFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_confirmPasswordFocus);
                            },
                            validator: (value) {
                              return SignupValidator.validatePassword(
                                value ?? '',
                              );
                            },
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
                            hintText: 'Confirm new password',
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              _handleResetPassword();
                            },
                            validator: (value) {
                              return SignupValidator.validateConfirmPassword(
                                _newPasswordController.text,
                                value ?? '',
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          Align(
                            alignment: Alignment.center,
                            child: GetStartedButton(
                              text: 'Reset ',
                              onComplete: _handleResetPassword,
                            ),
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
