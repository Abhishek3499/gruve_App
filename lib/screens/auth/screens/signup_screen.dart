import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/screens/complete_profile_screen.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/inputs/phone_input_field.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/widgets/inputs/neon_password_field.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';
import '../api/controllers/signup_controller.dart';

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

  // ── Form Key ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Other State ──────────────────────────────────────────
  final SignupController controller = SignupController();
  final GlobalKey _genderFieldKey = GlobalKey();
  String? selectedGender;
  bool _genderTouched = false;
  bool _useEmail = true;

  String? get _genderError => (_genderTouched && selectedGender == null)
      ? 'Please select gender'
      : null;

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
                      NeonTextField(
                        controller: _nameController,
                        hintText: 'Skyler',
                        prefixIcon: AppAssets.user2,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _formKey.currentState?.validate(); // 🔥 ADD THIS
                          FocusScope.of(context).requestFocus(_identifierFocus);
                        },
                        validator: (value) {
                          return SignupValidator.validateFullName(value ?? '');
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── TOGGLE ──────────────────────────────────────
                      _buildContactToggle(),
                      const SizedBox(height: 12),

                      // ── EMAIL / PHONE ───────────────────────────────
                      // ── EMAIL / PHONE ───────────────────────────────────────
                      _buildLabel(_useEmail ? 'Email' : 'Phone Number'),

                      // ✅ Toggle ke basis pe alag widget
                      if (_useEmail)
                        NeonTextField(
                          controller: _identifierController,
                          hintText: 'example@gmail.com',
                          prefixIcon: AppAssets.emailicon,
                          focusNode: _identifierFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            _formKey.currentState?.validate(); // 🔥 ADD THIS
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                          validator: (value) {
                            return SignupValidator.validateEmail(value ?? '');
                          },
                        )
                      else
                        PhoneInputField(
                          // ✅ phone wala widget
                          controller: _identifierController,
                          focusNode: _identifierFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            _formKey.currentState?.validate(); // 🔥 ADD THIS
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!RegExp(
                              r'^[6-9][0-9]{9}$',
                            ).hasMatch(value.trim())) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                      const SizedBox(height: 20),

                      // ── GENDER ──────────────────────────────────────
                      _buildLabel('Gender'),
                      GestureDetector(
                        key: _genderFieldKey,
                        onTap: () async {
                          setState(() => _genderTouched = true);
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
                                  color: _genderError != null
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
                              child: _genderError != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 5,
                                      ),
                                      child: Text(
                                        _genderError!,
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
                      NeonPasswordField(
                        controller: _passwordController,
                        hintText: '********',
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _formKey.currentState?.validate(); // 🔥 ADD THIS
                          FocusScope.of(
                            context,
                          ).requestFocus(_confirmPasswordFocus);
                        },
                        validator: (value) {
                          return SignupValidator.validatePassword(value ?? '');
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── CONFIRM PASSWORD ────────────────────────────
                      _buildLabel('Confirm Password'),
                      NeonPasswordField(
                        controller: _confirmPasswordController,
                        hintText: '********',
                        focusNode: _confirmPasswordFocus,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          return SignupValidator.validateConfirmPassword(
                            _passwordController.text,
                            value ?? '',
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // ── SIGN UP BUTTON ──────────────────────────────
                      GetStartedButton(
                        text: 'Sign Up',
                        onComplete: () async {
                          if (!mounted) return false;

                          // ✅ Gender touched mark — error dikhao agar empty
                          setState(() => _genderTouched = true);

                          // ✅ Sab fields validate
                          final isFormValid =
                              _formKey.currentState?.validate() == true;
                          final isGenderValid = selectedGender != null;

                          if (!isFormValid || !isGenderValid) return false;

                          final identifier = _identifierController.text.trim();

                          await controller.signup(
                            fullName: _nameController.text.trim(),
                            identifier: identifier,
                            password: _passwordController.text.trim(),
                            gender: selectedGender,
                          );

                          if (!context.mounted) return false;

                          if (controller.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(controller.errorMessage!)),
                            );
                            return false;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtpScreen(
                                identifier: identifier,
                                type: _useEmail ? "email" : "phone",
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
              isSelected: _useEmail,
              onTap: () => setState(() => _useEmail = true),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              title: 'Phone',
              isSelected: !_useEmail,
              onTap: () => setState(() => _useEmail = false),
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
    setState(() => selectedGender = selected);
  }
}
