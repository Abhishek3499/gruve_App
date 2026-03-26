import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/screens/auth/screens/complete_profile_screen.dart';
import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/screens/auth/validators/signup_validator.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/widgets/inputs/neon_password_field.dart';
import '../api/controllers/signup_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ✅ FIX 1: Controllers added to capture user input
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  final SignupController controller = SignupController();
  String? selectedGender;
  final GlobalKey _genderFieldKey = GlobalKey();
  bool _useEmail = true;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Always dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),

                    // FULL NAME
                    _buildLabel('Full Name'),
                    NeonTextField(
                      controller: _nameController, // ✅ Linked
                      hintText: 'Skyler',
                      prefixIcon: AppAssets.user2,
                    ),

                    const SizedBox(height: 20),

                    // EMAIL / PHONE
                    _buildContactToggle(),
                    const SizedBox(height: 12),
                    _buildLabel(_useEmail ? 'Email' : 'Phone Number'),
                    NeonTextField(
                      controller: _useEmail
                          ? _emailController
                          : _phoneController,
                      hintText: _useEmail
                          ? 'Loisbecket@gmail.com'
                          : 'Enter phone number',
                      prefixIcon: _useEmail ? AppAssets.emailicon : null,
                      keyboardType: _useEmail
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                    ),

                    const SizedBox(height: 20),
                    // GENDER
                    _buildLabel('Gender'),

                    GestureDetector(
                      key: _genderFieldKey,
                      onTap: _showGenderMenu,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFB86AD0)),
                          color: const Color(0xFF461851),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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

                    const SizedBox(height: 20),

                    // PASSWORD
                    _buildLabel('Password'),
                    NeonPasswordField(
                      controller:
                          _passwordController, // ✅ Make sure your widget accepts controller
                      hintText: '********',
                    ),

                    const SizedBox(height: 20),

                    // CONFIRM PASSWORD
                    _buildLabel('Confirm Password'),
                    NeonPasswordField(
                      controller: _confirmPasswordController, // ✅ Linked
                      hintText: '********',
                    ),

                    const SizedBox(height: 30),

                    // SIGN UP BUTTON
                    // SIGN UP BUTTON
                    GetStartedButton(
                      text: 'Sign Up',
                      onComplete: () async {
                        debugPrint("Button Clicked!"); // Debug ke liye

                        final identifierError = _useEmail
                            ? SignupValidator.validateEmail(
                                _emailController.text,
                              )
                            : _validatePhone(_phoneController.text);
                        final error =
                            SignupValidator.validateFullName(
                              _nameController.text,
                            ) ??
                            identifierError ??
                            SignupValidator.validatePassword(
                              _passwordController.text,
                            ) ??
                            SignupValidator.validateConfirmPassword(
                              _passwordController.text,
                              _confirmPasswordController.text,
                            );
                        if (selectedGender == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select gender"),
                            ),
                          );
                          return;
                        }

                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: const Color.fromARGB(
                                255,
                                233,
                                132,
                                125,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // ✅ password match validation
                        if (_passwordController.text !=
                            _confirmPasswordController.text) {
                          debugPrint("Password not match");

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match"),
                            ),
                          );
                          return;
                        }

                        // 🔥 API CALL
                        await controller.signup(
                          fullName: _nameController.text.trim(),
                          email: _useEmail
                              ? _emailController.text.trim()
                              : null,
                          phoneNumber: _useEmail
                              ? null
                              : _phoneController.text.trim(),
                          password: _passwordController.text.trim(),
                          gender: selectedGender,
                        );

                        if (!context.mounted) return;

                        // 🔥 RESPONSE HANDLE
                        if (controller.errorMessage != null) {
                          debugPrint("ERROR: ${controller.errorMessage}");

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(controller.errorMessage!)),
                          );

                          return; // ❗ IMPORTANT: yahi fix tha
                        }

                        debugPrint(
                          "SUCCESS: ${controller.signupResponse?.message}",
                        );

                        // ✅ SUCCESS → OTP SCREEN
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtpScreen(
                              identifier: _useEmail
                                  ? _emailController.text.trim()
                                  : _phoneController.text.trim(),
                              type: _useEmail ? "email" : "phone",

                              title: 'Enter your Code',
                              description:
                                  'Enter the 4-digit code sent to ${_useEmail ? _emailController.text : _phoneController.text}',
                              buttonText: 'Continue',

                              onVerified: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CompleteProfileScreen(),
                                  ),
                                );
                              },
                              isLogin: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 35),

                    // BACK TO LOGIN
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: Color(0xFFB86AD0),
                                fontWeight: FontWeight.w300,
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
            );
          },
        ),
      ),
    );
  }

  // Helper method to keep UI clean
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
        curve: Curves.easeOut,
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
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String value) {
    final phone = value.trim();
    if (phone.isEmpty) return "Phone number is required";
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(phone)) {
      return "Enter a valid phone number";
    }
    return null;
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
        PopupMenuItem(value: 'Male', child: Text('Male')),
        PopupMenuItem(value: 'Female', child: Text('Female')),
        PopupMenuItem(value: 'Other', child: Text('Other')),
      ],
    );

    if (selected == null || !mounted) return;
    setState(() {
      selectedGender = selected;
    });
  }
}
