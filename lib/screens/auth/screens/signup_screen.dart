import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth_flow.dart';
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
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  final SignupController controller = SignupController();
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Always dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
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

                    // EMAIL
                    _buildLabel('Email'),
                    NeonTextField(
                      controller: _emailController, // ✅ Linked
                      hintText: 'Loisbecket@gmail.com',
                      prefixIcon: AppAssets.emailicon,
                      keyboardType: TextInputType.emailAddress,
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
                        print("Button Clicked!"); // Debug ke liye

                        final error = SignupValidator.validateAll(
                          fullName: _nameController.text,
                          email: _emailController.text,
                          password: _passwordController.text,
                          confirmPassword: _confirmPasswordController.text,
                        );

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
                          print("Password not match");

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
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );

                        if (!mounted) return;

                        // 🔥 RESPONSE HANDLE
                        if (controller.errorMessage != null) {
                          print("ERROR: ${controller.errorMessage}");

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(controller.errorMessage!)),
                          );

                          return; // ❗ IMPORTANT: yahi fix tha
                        }

                        print("SUCCESS: ${controller.signupResponse?.message}");

                        // ✅ SUCCESS → OTP SCREEN
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtpScreen(
                              identifier: _emailController.text.trim(), // ✅ NEW
                              type: "email", // ✅ NEW

                              title: 'Enter your Code',
                              description:
                                  'Enter the 4-digit code sent to ${_emailController.text}',
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
}
