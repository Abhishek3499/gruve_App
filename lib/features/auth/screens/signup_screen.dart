// ignore_for_file: use_build_context_synchronously

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
  bool _nameTouched = false;
  bool _identifierTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;



  // ── Other State ──────────────────────────────────────────

  final SignupController controller = SignupController();
  final GetStartedButtonController _signupButtonController =
      GetStartedButtonController();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _identifierKey = GlobalKey();
  final GlobalKey _genderFieldKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _confirmPasswordKey = GlobalKey();
  OverlayEntry? _genderDropdownEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isGenderMenuOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetSignup();
    });
    _setupRealTimeValidation();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) {
        _scrollToField(_nameKey);
        if (mounted && _isGenderMenuOpen) {
          _hideGenderMenu();
        }
      }
    });
    _identifierFocus.addListener(() {
      if (_identifierFocus.hasFocus) {
        _scrollToField(_identifierKey);
        if (mounted && _isGenderMenuOpen) {
          _hideGenderMenu();
        }
      }
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _scrollToField(_passwordKey);
        if (mounted && _isGenderMenuOpen) {
          _hideGenderMenu();
        }
      }
    });
    _confirmPasswordFocus.addListener(() {
      if (_confirmPasswordFocus.hasFocus) {
        _scrollToField(_confirmPasswordKey);
        if (mounted && _isGenderMenuOpen) {
          _hideGenderMenu();
        }
      }
    });
  }

  void _scrollToField(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final targetContext = key.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
        }
      });
    });
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

    if (mounted) {
      setState(() {
        _identifierTouched = false;
      });
    }

    authUi.setContactMode(useEmail);
    _identifierFocus.unfocus();
    _identifierController.clear();
    authUi.setError('signup_identifier', null);
  }

  @override
  void dispose() {
    _hideGenderMenu();
    _nameController.dispose();

    _identifierController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    _nameFocus.dispose();

    _identifierFocus.dispose();

    _passwordFocus.dispose();

    _confirmPasswordFocus.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.signup),
    );
    final selectedGender = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.selectedGender,
    );
    final genderError = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.genderError,
    );
    final useEmail = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.useEmail,
    );
    final nameErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('signup_name'),
    );
    final identifierErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('signup_identifier'),
    );
    final passwordErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('signup_password'),
    );
    final confirmPasswordErrorRaw = context.select<AuthUiProvider, String?>(
      (authUi) => authUi.error('signup_confirm_password'),
    );

    final nameError = _nameTouched ? nameErrorRaw : null;
    final identifierError = _identifierTouched ? identifierErrorRaw : null;
    final passwordError = _passwordTouched ? passwordErrorRaw : null;
    final confirmPasswordError = _confirmPasswordTouched ? confirmPasswordErrorRaw : null;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: Colors.black,

      body: VideoBackground(
        videoPath: AppAssets.splashVideo,

        overlayOpacity: 0.85,

        child: LayoutBuilder(
          builder: (layoutContext, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: Form(
                // ✅ Form wrap
                key: _formKey,

                child: SingleChildScrollView(
                  controller: _scrollController,
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
                        key: _nameKey,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          NeonTextField(
                            controller: _nameController,

                            hintText: 'Enter your name',

                            prefixIcon: AppAssets.user2,

                            focusNode: _nameFocus,

                            textInputAction: TextInputAction.next,

                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_identifierFocus);
                            },
                            errorText: nameError,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── TOGGLE ──────────────────────────────────────
                      _buildContactToggle(useEmail),

                      const SizedBox(height: 12),

                      // ── EMAIL / PHONE ───────────────────────────────
                      _buildLabel(useEmail ? 'Email' : 'Phone Number'),

                      Column(
                        key: _identifierKey,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ✅ Toggle ke basis pe alag widget
                          if (useEmail)
                            NeonTextField(
                              controller: _identifierController,

                              hintText: 'Enter your Email',

                              prefixIcon: AppAssets.emailicon,

                              focusNode: _identifierFocus,

                              keyboardType: TextInputType.emailAddress,

                              textInputAction: TextInputAction.next,

                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus);
                              },
                              errorText: identifierError,
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
                              errorText: identifierError,
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── GENDER ──────────────────────────────────────
                      _buildLabel('Gender'),

                      GestureDetector(
                        key: _genderFieldKey,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _showGenderMenu();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CompositedTransformTarget(
                              link: _layerLink,
                              child: Container(
                                width: double.infinity,

                                height: 56,

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),

                                  border: Border.all(
                                    color: genderError != null
                                        ? const Color(0xFFFF6B6B) // ✅ red
                                        : const Color(0xFFAF50C4),
                                    width: 1.0,
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

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        selectedGender ?? 'Select Gender',

                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: selectedGender == null
                                              ? FontWeight.w700
                                              : FontWeight.normal,
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
                        key: _passwordKey,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          NeonPasswordField(
                            controller: _passwordController,

                            hintText: 'Enter Your Password',

                            focusNode: _passwordFocus,

                            textInputAction: TextInputAction.next,

                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_confirmPasswordFocus);
                            },
                            errorText: passwordError,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── CONFIRM PASSWORD ────────────────────────────
                      _buildLabel('Confirm Password'),

                      Column(
                        key: _confirmPasswordKey,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          NeonPasswordField(
                            controller: _confirmPasswordController,

                            hintText: 'Confirm Your Password',

                            focusNode: _confirmPasswordFocus,

                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                _signupButtonController.submit(),
                            errorText: confirmPasswordError,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ── SIGN UP BUTTON ──────────────────────────────
                      GetStartedButton(
                        controller: _signupButtonController,

                        text: 'Sign Up',

                        isLoading: isLoading,

                        onComplete: () async {
                          if (!mounted) return false;
                          FocusScope.of(context).unfocus();

                          // ✅ Gender touched mark — error dikhao agar empty

                          final authUi = context.read<AuthUiProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          if (authUi.isLoading(AuthLoadingKey.signup)) {
                            return false;
                          }
                          authUi.touchGender();

                          if (mounted) {
                            setState(() {
                              _nameTouched = true;
                              _identifierTouched = true;
                              _passwordTouched = true;
                              _confirmPasswordTouched = true;
                            });
                          }

                          final isValid = _validateBeforeSubmit();

                          if (!isValid) {
                            if (!mounted) return false;

                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
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
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(controller.errorMessage!),
                                ),
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
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CompleteProfileScreen(),
                                    ),
                                    (route) => false,
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
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFFB86AD0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildContactToggle(bool useEmail) {
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

              isSelected: useEmail,

              onTap: () => _setContactMode(true),
            ),
          ),

          Expanded(
            child: _buildToggleOption(
              title: 'Phone',

              isSelected: !useEmail,

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

  void _hideGenderMenu() {
    if (mounted && _isGenderMenuOpen) {
      setState(() {
        _isGenderMenuOpen = false;
      });
    }
    _genderDropdownEntry?.remove();
    _genderDropdownEntry = null;
  }

  void _showGenderMenu() {
    _hideGenderMenu();

    setState(() {
      _isGenderMenuOpen = true;
    });

    final context = _genderFieldKey.currentContext;
    if (context == null) return;

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Size size = box.size;

    _genderDropdownEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideGenderMenu,
              child: const SizedBox.expand(),
            ),
            Positioned(
              width: 130,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(size.width - 165, 56 + 4),
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFAF50C4), width: 1.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF461851),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGenderOption('Male', Icons.male),
                        _buildGenderOption('Female', Icons.female),
                        _buildGenderOption('Other', Icons.transgender),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(this.context).insert(_genderDropdownEntry!);
  }

  Widget _buildGenderOption(String value, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _hideGenderMenu();
          if (!mounted) return;
          context.read<AuthUiProvider>().setGender(value);
          FocusScope.of(context).requestFocus(_passwordFocus);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFB86AD0), size: 18),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
