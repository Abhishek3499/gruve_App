import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

import 'package:gruve_app/features/auth/presentation/notifiers/reset_password_notifier.dart';

import 'package:gruve_app/features/auth/data/services/token_storage.dart';

import 'package:gruve_app/shared/widgets/get_started_button.dart';

import 'package:gruve_app/shared/widgets/video_background.dart';

import 'package:gruve_app/features/auth/presentation/widgets/inputs/neon_password_field.dart';

import 'package:gruve_app/features/auth/presentation/screens/email_login_screen.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String identifier;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.identifier,
    required this.otp,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GetStartedButtonController _resetButtonController =
      GetStartedButtonController();

  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  final FocusNode _newPasswordFocus = FocusNode();
  late final FocusNode _confirmPasswordFocus;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(resetPasswordNotifierProvider.notifier).reset();
    });

    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _confirmPasswordFocus = FocusNode();

    _newPasswordController.addListener(_validatePasswords);
    _confirmPasswordController.addListener(_validatePasswords);
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

    if (mounted) {
      setState(() {
        _passwordError = passwordError;
        _confirmPasswordError = confirmPasswordError;
      });
    }

    return passwordError == null && confirmPasswordError == null;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(resetPasswordNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: context.rw(24),
                  top: context.rh(9),
                ),

                child: Align(
                  alignment: Alignment.topLeft,

                  child: BackButton(
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.rw(24)),

                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        SizedBox(height: constraints.maxHeight * 0.18),

                        RichText(
                          textAlign: TextAlign.start,

                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white,

                              fontSize: context.rf(26),

                              fontWeight: FontWeight.w700,

                              fontFamily: AppAssets.syncopateFont,
                            ),

                            children: [
                              TextSpan(text: 'Reset '),

                              TextSpan(
                                text: 'Password',

                                style: TextStyle(
                                  color: AppColors.lavenderPurple,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: context.rh(12)),

                        Text(
                          'Create a new password for your account.\nMake sure it\'s strong and secure.',

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: Colors.white,

                            fontSize: context.rf(16),

                            fontWeight: FontWeight(400),
                          ),
                        ),

                        SizedBox(height: context.rh(40)),

                        Align(
                          alignment: Alignment.centerLeft,

                          child: Text(
                            'Password',

                            style: TextStyle(
                              color: Color(0xFFFFFFFF),

                              fontSize: context.rf(16),

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: context.rh(10)),

                        NeonPasswordField(
                          hintText: 'Enter Your Password',

                          controller: _newPasswordController,
                          focusNode: _newPasswordFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _confirmPasswordFocus.requestFocus(),
                          errorText: _passwordTouched ? _passwordError : null,
                        ),

                        SizedBox(height: context.rh(20)),

                        Align(
                          alignment: Alignment.centerLeft,

                          child: Text(
                            'Confirm Password',

                            style: TextStyle(
                              color: Color(0xFFFFFFFF),

                              fontSize: context.rf(16),

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: context.rh(10)),

                        NeonPasswordField(
                          hintText: 'Confirm Your Password',

                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _resetButtonController.submit(),
                          errorText: _confirmPasswordTouched
                              ? _confirmPasswordError
                              : null,
                        ),

                        SizedBox(height: context.rh(40)),

                        Align(
                          alignment: AlignmentGeometry.center,

                          child: GetStartedButton(
                            controller: _resetButtonController,

                            text: 'Reset ',

                            isLoading: isLoading,

                            onComplete: () async {
                              if (mounted) {
                                setState(() {
                                  _passwordTouched = true;
                                  _confirmPasswordTouched = true;
                                });
                              }
                              final resetPasswordNotifier = ref.read(
                                resetPasswordNotifierProvider.notifier,
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(context);
                              final password = _newPasswordController.text
                                  .trim();
                              if (ref
                                  .read(resetPasswordNotifierProvider)
                                  .isLoading) {
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

                              // 🔥 CALL API

                              final result = await resetPasswordNotifier
                                  .resetPassword(
                                    identifier: widget.identifier,
                                    otp: widget.otp,
                                    password: password,
                                  );

                              if (!mounted) return false;

                              if (result.isSuccess) {
                                // ✅ CLEAR TOKEN AFTER SUCCESS

                                await TokenStorage.clearResetToken();

                                if (!mounted) return false;

                                messenger
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(content: Text(result.message)),
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
                                messenger
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(result.message),

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
