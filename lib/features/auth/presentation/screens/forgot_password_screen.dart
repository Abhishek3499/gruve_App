import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gruve_app/core/constants/app_assets.dart';

import 'package:gruve_app/features/auth/presentation/notifiers/forgot_password_notifier.dart';

import 'package:gruve_app/features/auth/presentation/screens/otp_screen.dart';

import 'package:gruve_app/features/auth/presentation/screens/reset_password_screen.dart';

import 'package:gruve_app/shared/widgets/get_started_button.dart';

import 'package:gruve_app/shared/widgets/video_background.dart';

import 'package:gruve_app/features/auth/presentation/widgets/inputs/neon_text_field.dart';

import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final FocusNode _emailFocus = FocusNode();
  bool _emailTouched = false;

  final GetStartedButtonController _forgotButtonController =
      GetStartedButtonController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(forgotPasswordNotifierProvider.notifier).reset();
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

      ref.read(forgotPasswordNotifierProvider.notifier).setEmailError(error);
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
    final forgotPasswordState = ref.watch(forgotPasswordNotifierProvider);
    final isLoading = forgotPasswordState.isLoading;
    final emailErrorRaw = forgotPasswordState.emailError;
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
                                    style: TextStyle(
                                      color: AppColors.lavenderPurple,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          SizedBox(height: context.rh(12)),
                          Text(
                            'Please enter your valid email. We will send you a 4-digit code to verify your account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rf(16),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: context.rh(40)),
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
                          NeonTextField(
                            controller: _emailController,
                            hintText: 'Enter your Email',
                            prefixIcon: AppAssets.emailicon,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            focusNode: _emailFocus,
                            onFieldSubmitted: (_) => _emailFocus.unfocus(),
                            errorText: emailError,
                          ),
                          SizedBox(height: context.rh(40)),
                          Center(
                            child: GetStartedButton(
                              controller: _forgotButtonController,
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
                                final forgotPasswordNotifier = ref.read(
                                  forgotPasswordNotifierProvider.notifier,
                                );
                                if (ref
                                    .read(forgotPasswordNotifierProvider)
                                    .isLoading) {
                                  return false;
                                }

                                final emailError =
                                    SignupValidator.validateEmailRealTime(
                                      email,
                                    );
                                forgotPasswordNotifier.setEmailErrorNow(
                                  emailError,
                                );

                                if (emailError != null) {
                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(content: Text(emailError)),
                                    );
                                  return false;
                                }

                                final result = await forgotPasswordNotifier
                                    .sendResetLink(email);

                                if (!mounted) return false;

                                if (!result.isSuccess) {
                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result.errorMessage ??
                                              'We could not send the reset code. Please try again.',
                                        ),
                                      ),
                                    );
                                  return false;
                                }

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
                                            builder: (_) => ResetPasswordScreen(
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
