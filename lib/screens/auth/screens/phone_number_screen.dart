import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/api/controllers/login_controller.dart';

import 'package:gruve_app/screens/auth/screens/otp_screen.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/screens/auth/screens/signup_screen.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/inputs/phone_input_field.dart';
import 'package:gruve_app/widgets/video_background.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final EmailSignInController _controller = EmailSignInController();
  late final TextEditingController _phoneController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
        child: SafeArea(
          child: Stack(
            children: [
              /// BACK BUTTON
              Positioned(
                top: 4,
                left: 24,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(AppAssets.back, height: 22, width: 22),
                ),
              ),

              /// MAIN CONTENT
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.26,
                      ),

                      /// TITLE
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontFamily: AppAssets.syncopateFont,
                          ),
                          children: [
                            TextSpan(text: 'Phone '),
                            TextSpan(
                              text: 'Number',
                              style: TextStyle(
                                color: Color(0xFFB86AD0),
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// DESCRIPTION
                      const Text(
                        'Please enter your valid number. we will send\n'
                        'you a 4- digit code to verify your account.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 26),

                      /// LABEL
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// PHONE INPUT
                      PhoneInputField(controller: _phoneController),

                      const SizedBox(height: 36),

                      /// LOGIN BUTTON
                      const SizedBox(height: 36),

                      /// LOGIN BUTTON
                      Center(
                        child: // ... baki imports same ...
                            // Login button ke onComplete ko replace karein:
                            GetStartedButton(
                              text: 'Login',
                              isLoading: isLoading,
                              onComplete: () async {
                                final phone = _phoneController.text.trim();

                                if (phone.isEmpty || phone.length < 7) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Enter valid phone number"),
                                    ),
                                  );
                                  return;
                                }

                                debugPrint("📤 Sending OTP to: $phone");

                                // 🔥 ADD THIS
                                debugPrint("📤 Sending OTP to: $phone");

                                // 🔥 ADD FROM HERE
                                final dio = Dio(
                                  BaseOptions(baseUrl: dotenv.env['BASE_URL']!),
                                );

                                try {
                                  final response = await dio.post(
                                    "auth/login/",
                                    data: {
                                      "phone_number": phone,
                                      "type": "phone",
                                    },
                                  );

                                  debugPrint("✅ OTP SENT: ${response.data}");
                                } catch (e) {
                                  if (e is DioException) {
                                    debugPrint(
                                      "❌ STATUS: ${e.response?.statusCode}",
                                    );
                                    debugPrint("❌ DATA: ${e.response?.data}");
                                  } else {
                                    debugPrint("❌ ERROR: $e");
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("OTP failed")),
                                  );
                                  return;
                                }
                                // 🔥 ADD TILL HERE

                                // ✅ NAVIGATION (already correct)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtpScreen(
                                      identifier: phone,
                                      type: "phone",
                                      title: 'Enter your Code',
                                      description:
                                          'Enter the 4-digit code sent to your phone number.',
                                      buttonText: 'Continue',
                                      isLogin: true,
                                      onVerified: () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const HomeScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),

                      const SizedBox(height: 90),

                      /// SIGNUP
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Don't have an account?  ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppAssets.montserratfont,
                                  ),
                                ),
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                    color: Color(0xFFB86AD0),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: AppAssets.montserratfont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
