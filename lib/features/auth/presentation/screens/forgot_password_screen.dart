import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/forgot_password_service.dart';
import 'package:gruve_app/features/auth/presentation/controller/auth_ui_provider.dart';
import 'package:provider/provider.dart';

import 'package:gruve_app/features/auth/presentation/screens/otp_screen.dart';

import 'package:gruve_app/features/auth/presentation/screens/reset_password_screen.dart';

import 'package:gruve_app/shared/widgets/get_started_button.dart';

import 'package:gruve_app/shared/widgets/video_background.dart';

import 'package:gruve_app/shared/widgets/inputs/neon_text_field.dart';

import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final FocusNode _emailFocus = FocusNode();
  bool _emailTouched = false;

  final ForgotPasswordService _service = ForgotPasswordService();
  final GetStartedButtonController _forgotButtonController =
      GetStartedButtonController();

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

      context.read<AuthUiProvider>().setValidationError('forgot_email', error);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.forgotPassword),
    );
    final emailErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('forgot_email'),
    );
    final emailError = _emailTouched ? emailErrorRaw : null;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(24),
                        vertical: context.rh(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.rf(26),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppAssets.syncopateFont,
                                ),
                                children: const [
                                  TextSpan(text: 'FORGOT '),
                                  TextSpan(
                                    text: 'PASSWORD',
                                    style: TextStyle(color: Color(0xFFB86AD0)),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          SizedBox(height: context.rh(12)),
                          Text(
                            'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rf(15),
                            ),
                          ),
                          SizedBox(height: context.rh(40)),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.rf(16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: context.rh(10)),
                          NeonTextField(
                            controller: _emailController,
                            hintText: 'Enter your Email',
                            prefixIcon: AppAssets.user2,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            focusNode: _emailFocus,
                            onFieldSubmitted: (_) =>
                                _forgotButtonController.submit(),
                            errorText: emailError,
                          ),
                          SizedBox(height: context.rh(40)),
                          Center(
                            child: GetStartedButton(
                              controller: _forgotButtonController,
                              width: 250,
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: context.rf(13),
                                fontWeight: FontWeight.bold,
                                fontFamily: AppAssets.syncopateFont,
                              ),
                              text: 'RESET PASSWORD',
                              isLoading: isLoading,
                              onComplete: () async {
                                if (mounted) {
                                  setState(() {
                                    _emailTouched = true;
                                  });
                                }
                                final email = _emailController.text.trim();
                                if (!mounted) return false;
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(context);
                                final authUi = context.read<AuthUiProvider>();
                                if (authUi.isLoading(
                                  AuthLoadingKey.forgotPassword,
                                )) {
                                  return false;
                                }

                                final emailError =
                                    SignupValidator.validateEmailRealTime(
                                      email,
                                    );
                                authUi.setError('forgot_email', emailError);

                                if (emailError != null) {
                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
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
                                  await _service.sendResetLink(
                                    identifier: email,
                                  );
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
                                              builder: (_) =>
                                                  ResetPasswordScreen(
                                                    identifier: email,
                                                    otp: token,
                                                  ),
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

                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AuthApiException.userFacingMessage(
                                            e,
                                            fallback:
                                                'We could not send the reset code. Please try again.',
                                          ),
                                        ),
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
                  ),
                );
              },
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: context.rw(24),
                  top: context.rh(33),
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
