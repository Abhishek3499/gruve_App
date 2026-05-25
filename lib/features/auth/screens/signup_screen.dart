import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/features/auth/screens/complete_profile_screen.dart';

import 'package:gruve_app/features/auth/screens/otp_screen.dart';

import 'package:gruve_app/core/widgets/get_started_button.dart';

import 'package:gruve_app/core/widgets/inputs/phone_input_field.dart';

import 'package:gruve_app/core/widgets/video_background.dart';

import 'package:gruve_app/core/widgets/inputs/neon_text_field.dart';

import 'package:gruve_app/core/widgets/inputs/neon_password_field.dart';

import '../api/controllers/signup_controller.dart';
import '../presentation/provider/auth_ui_provider.dart';
import '../validators/phone_number_validator.dart';
import '../validators/signup_validator.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ── Controllers ──────────────────────────────────────────

  final _nameController = TextEditingController();

  final _identifierController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  // ── Focus Nodes ──────────────────────────────────────────

  final _nameFocus = FocusNode();

  final _identifierFocus = FocusNode();

  final _passwordFocus = FocusNode();

  final _confirmPasswordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  // ── Real-time Validation State ───────────────────────────

  // ── Other State ──────────────────────────────────────────

  final SignupController controller = SignupController();

  final GlobalKey _genderFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetSignup();
    });
    _setupRealTimeValidation();
  }

  void _setupRealTimeValidation() {
    // Name field real-time validation

    _nameController.addListener(() {
      final error = SignupValidator.validateFullNameRealTime(
        _nameController.text,
      );

      context.read<AuthUiProvider>().setError('signup_name', error);
    });

    // Identifier field real-time validation

    _identifierController.addListener(() {
      final error = _validateIdentifier(_identifierController.text);

      context.read<AuthUiProvider>().setError('signup_identifier', error);
    });

    // Password field real-time validation

    _passwordController.addListener(() {
      final error = SignupValidator.validatePasswordRealTime(
        _passwordController.text,
      );

      context.read<AuthUiProvider>().setError('signup_password', error);

      // Revalidate confirm password when password changes

      if (_confirmPasswordController.text.isNotEmpty) {
        final confirmError = SignupValidator.validateConfirmPasswordRealTime(
          _passwordController.text,

          _confirmPasswordController.text,
        );

        context.read<AuthUiProvider>().setError(
          'signup_confirm_password',
          confirmError,
        );
      }
    });

    // Confirm password field real-time validation

    _confirmPasswordController.addListener(() {
      final error = SignupValidator.validateConfirmPasswordRealTime(
        _passwordController.text,

        _confirmPasswordController.text,
      );

      context.read<AuthUiProvider>().setError('signup_confirm_password', error);
    });
  }

  String? _validateIdentifier(String identifier) {
    final trimmed = identifier.trim();

    if (context.read<AuthUiProvider>().useEmail) {
      return SignupValidator.validateEmailRealTime(trimmed);
    }

    return PhoneNumberValidator.validatePhoneRealTime(trimmed);
  }

  bool _validateBeforeSubmit() {
    final nameError = SignupValidator.validateFullNameRealTime(
      _nameController.text,
    );
    final identifierError = _validateIdentifier(_identifierController.text);
    final passwordError = SignupValidator.validatePasswordRealTime(
      _passwordController.text,
    );
    final confirmPasswordError =
        SignupValidator.validateConfirmPasswordRealTime(
          _passwordController.text,
          _confirmPasswordController.text,
        );

    final authUi = context.read<AuthUiProvider>();
    authUi.setErrors({
      'signup_name': nameError,
      'signup_identifier': identifierError,
      'signup_password': passwordError,
      'signup_confirm_password': confirmPasswordError,
    });

    return nameError == null &&
        identifierError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        authUi.selectedGender != null;
  }

  String _firstSignupError() {
    final authUi = context.read<AuthUiProvider>();
    return authUi.error('signup_name') ??
        authUi.error('signup_identifier') ??
        authUi.error('signup_password') ??
        authUi.error('signup_confirm_password') ??
        authUi.genderError ??
        'Please complete all required fields';
  }

  void _setContactMode(bool useEmail) {
    final authUi = context.read<AuthUiProvider>();
    if (authUi.useEmail == useEmail) return;

    authUi.setContactMode(useEmail);
    authUi.setError(
      'signup_identifier',
      _validateIdentifier(_identifierController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();

    _identifierController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    _nameFocus.dispose();

    _identifierFocus.dispose();

    _passwordFocus.dispose();

    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUi = context.watch<AuthUiProvider>();
    final isLoading = authUi.isLoading(AuthLoadingKey.signup);
    final selectedGender = authUi.selectedGender;
    final genderError = authUi.genderError;
    final useEmail = authUi.useEmail;
    final nameError = authUi.error('signup_name');
    final identifierError = authUi.error('signup_identifier');
    final passwordError = authUi.error('signup_password');
    final confirmPasswordError = authUi.error('signup_confirm_password');

    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: Form(
                // ✅ Form wrap
                key: _formKey,

                autovalidateMode: AutovalidateMode.onUserInteraction,

                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.15),

                      // TITLE
                      Align(
                        alignment: AlignmentDirectional.topStart,

                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 28,

                              fontWeight: FontWeight.w700,

                              letterSpacing: 1.0,

                              fontFamily: AppAssets.syncopateFont,
                            ),

                            children: [
                              TextSpan(text: 'Sign'),

                              TextSpan(
                                text: ' Up',

                                style: TextStyle(color: Color(0xFFB86AD0)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Align(
                        alignment: Alignment.centerLeft,

                        child: Text(
                          'Create Your Account',

                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 38),

                      // ── FULL NAME ───────────────────────────────────
                      _buildLabel('Full Name'),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          NeonTextField(
                            controller: _nameController,

                            hintText: 'Skyler',

                            prefixIcon: AppAssets.user2,

                            focusNode: _nameFocus,

                            textInputAction: TextInputAction.next,

                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_identifierFocus);
                            },
                          ),

                          if (nameError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 5),

                              child: Text(
                                nameError,

                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),

                                  fontSize: 11,

                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── TOGGLE ──────────────────────────────────────
                      _buildContactToggle(),

                      const SizedBox(height: 12),

                      // ── EMAIL / PHONE ───────────────────────────────
                      _buildLabel(useEmail ? 'Email' : 'Phone Number'),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ✅ Toggle ke basis pe alag widget
                          if (useEmail)
                            NeonTextField(
                              controller: _identifierController,

                              hintText: 'example@gmail.com',

                              prefixIcon: AppAssets.emailicon,

                              focusNode: _identifierFocus,

                              keyboardType: TextInputType.emailAddress,

                              textInputAction: TextInputAction.next,

                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus);
                              },
                            )
                          else
                            PhoneInputField(
                              // ✅ phone wala widget
                              controller: _identifierController,

                              focusNode: _identifierFocus,

                              textInputAction: TextInputAction.next,

                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus);
                              },
                            ),

                          if (identifierError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 5),

                              child: Text(
                                identifierError,

                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),

                                  fontSize: 11,

                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── GENDER ──────────────────────────────────────
                      _buildLabel('Gender'),

                      GestureDetector(
                        key: _genderFieldKey,

                        onTap: () async {
                          final authUi = context.read<AuthUiProvider>();
                          authUi.touchGender();

                          await _showGenderMenu();
                        },

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Container(
                              width: double.infinity,

                              height: 56,

                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),

                                border: Border.all(
                                  color: genderError != null
                                      ? const Color(0xFFFF6B6B) // ✅ red
                                      : const Color(0xFFB86AD0),
                                ),

                                color: const Color(0xFF461851),
                              ),

                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),

                              child: Row(
                                children: [
                                  Image.asset(
                                    AppAssets.user2,

                                    width: 22,

                                    height: 22,

                                    color: const Color(0x99FF00FF),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      selectedGender ?? 'Select Gender',

                                      style: TextStyle(
                                        color: selectedGender == null
                                            ? Colors.white54
                                            : Colors.white,
                                      ),
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_drop_down,

                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),

                            // ✅ Gender error bahar
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),

                              child: genderError != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,

                                        top: 5,
                                      ),

                                      child: Text(
                                        genderError,

                                        style: const TextStyle(
                                          color: Color(0xFFFF6B6B),

                                          fontSize: 11,

                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── PASSWORD ────────────────────────────────────
                      _buildLabel('Password'),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          NeonPasswordField(
                            controller: _passwordController,

                            hintText: '********',

                            focusNode: _passwordFocus,

                            textInputAction: TextInputAction.next,

                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_confirmPasswordFocus);
                            },
                          ),

                          if (passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 5),

                              child: Text(
                                passwordError,

                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),

                                  fontSize: 11,

                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── CONFIRM PASSWORD ────────────────────────────
                      _buildLabel('Confirm Password'),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          NeonPasswordField(
                            controller: _confirmPasswordController,

                            hintText: '********',

                            focusNode: _confirmPasswordFocus,

                            textInputAction: TextInputAction.done,
                          ),

                          if (confirmPasswordError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 5),

                              child: Text(
                                confirmPasswordError,

                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),

                                  fontSize: 11,

                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ── SIGN UP BUTTON ──────────────────────────────
                      GetStartedButton(
                        text: 'Sign Up',

                        isLoading: isLoading,

                        onComplete: () async {
                          if (!mounted) return false;

                          // ✅ Gender touched mark — error dikhao agar empty

                          final authUi = context.read<AuthUiProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          authUi.touchGender();

                          final isValid = _validateBeforeSubmit();

                          if (!isValid) {
                            if (!mounted) return false;

                            messenger.showSnackBar(
                              SnackBar(content: Text(_firstSignupError())),
                            );
                            return false;
                          }

                          authUi.setLoading(AuthLoadingKey.signup, true);

                          final identifier = _identifierController.text.trim();

                          try {
                            await controller.signup(
                              fullName: _nameController.text.trim(),

                              identifier: identifier,

                              password: _passwordController.text.trim(),

                              gender: selectedGender,
                            );
                          } finally {
                            if (mounted) {
                              authUi.setLoading(AuthLoadingKey.signup, false);
                            }
                          }

                          if (!mounted) return false;

                          if (controller.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(controller.errorMessage!)),
                            );

                            return false;
                          }

                          if (!mounted) return false;

                          if (!nav.mounted) return false;
                          nav.push(
                            MaterialPageRoute(
                              builder: (context) => OtpScreen(
                                identifier: identifier,

                                type: useEmail ? "email" : "phone",

                                title: 'Enter your Code',

                                description:
                                    'Enter the code sent to $identifier',

                                buttonText: 'Continue',

                                isLogin: false,

                                onVerified: () {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CompleteProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );

                          return true;
                        },
                      ),

                      const SizedBox(height: 35),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),

                        child: const Text(
                          'Already have an account? Sign In',

                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Align(
        alignment: Alignment.centerLeft,

        child: Text(
          text,

          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildContactToggle() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: const Color(0xFF461851),

        borderRadius: BorderRadius.circular(26),

        border: Border.all(color: const Color(0xFFB86AD0)),
      ),

      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              title: 'Email',

              isSelected: context.watch<AuthUiProvider>().useEmail,

              onTap: () => _setContactMode(true),
            ),
          ),

          Expanded(
            child: _buildToggleOption(
              title: 'Phone',

              isSelected: !context.watch<AuthUiProvider>().useEmail,

              onTap: () => _setContactMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,

    required bool isSelected,

    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        height: 44,

        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB86AD0) : Colors.transparent,

          borderRadius: BorderRadius.circular(22),
        ),

        alignment: Alignment.center,

        child: Text(
          title,

          style: TextStyle(
            color: Colors.white,

            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showGenderMenu() async {
    final context = _genderFieldKey.currentContext;

    if (context == null) return;

    final RenderBox box = context.findRenderObject()! as RenderBox;

    final Offset topLeft = box.localToGlobal(Offset.zero);

    final Size size = box.size;

    final selected = await showMenu<String>(
      context: this.context,

      color: const Color(0xFF461851),

      position: RelativeRect.fromLTRB(
        topLeft.dx,

        topLeft.dy + size.height + 6,

        topLeft.dx + size.width,

        0,
      ),

      items: const [
        PopupMenuItem(
          value: 'Male',

          child: Text('Male', style: TextStyle(color: Colors.white)),
        ),

        PopupMenuItem(
          value: 'Female',

          child: Text('Female', style: TextStyle(color: Colors.white)),
        ),

        PopupMenuItem(
          value: 'Other',

          child: Text('Other', style: TextStyle(color: Colors.white)),
        ),
      ],
    );

    if (selected == null || !mounted) return;

    this.context.read<AuthUiProvider>().setGender(selected);
  }
}
