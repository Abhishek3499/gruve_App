import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/screens/auth/api/services/forgot_password_service.dart';



import 'package:gruve_app/screens/auth/screens/otp_screen.dart';

import 'package:gruve_app/screens/auth/screens/reset_password_screen.dart';

import 'package:gruve_app/widgets/get_started_button.dart';

import 'package:gruve_app/widgets/video_background.dart';

import 'package:gruve_app/widgets/inputs/neon_text_field.dart';

import '../validators/signup_validator.dart';



class ForgotPasswordScreen extends StatefulWidget {

  const ForgotPasswordScreen({super.key});



  @override

  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();

}



class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  late final TextEditingController _emailController;

  bool isLoading = false;

  final ForgotPasswordService _service = ForgotPasswordService();

  // Real-time validation state

  String? _emailError;



  @override

  void initState() {

    super.initState();

    _emailController = TextEditingController();

    _setupRealTimeValidation();

  }



  void _setupRealTimeValidation() {

    // Email field real-time validation

    _emailController.addListener(() {

      final error = SignupValidator.validateEmailRealTime(_emailController.text);

      if (error != _emailError) {

        setState(() => _emailError = error);

      }

    });

  }



  @override

  void dispose() {

    _emailController.dispose();

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

        child: Stack(

          children: [

            SafeArea(

              child: Padding(

                padding: const EdgeInsets.only(left: 16, top: 10),

                child: GestureDetector(

                  onTap: () {

                    if (Navigator.canPop(context)) {

                      Navigator.pop(context);

                    }

                  },

                  child: Image.asset(AppAssets.back, height: 25, width: 25),

                ),

              ),

            ),

            LayoutBuilder(

              builder: (context, constraints) {

                return Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: SingleChildScrollView(

                    keyboardDismissBehavior:

                        ScrollViewKeyboardDismissBehavior.onDrag,

                    child: Column(

                      children: [

                        SizedBox(height: constraints.maxHeight * 0.18),



                        FittedBox(

                          fit: BoxFit.scaleDown,

                          child: Text.rich(

                            TextSpan(

                              style: const TextStyle(

                                color: Colors.white,

                                fontSize: 26,

                                fontWeight: FontWeight.w700,



                                fontFamily: AppAssets.syncopateFont,

                              ),

                              children: const [

                                TextSpan(text: 'Forgot '),

                                TextSpan(

                                  text: 'Password ',

                                  style: TextStyle(color: Color(0xFFB86AD0)),

                                ),

                              ],

                            ),

                            maxLines: 1,

                            softWrap: false,

                          ),

                        ),



                        const SizedBox(height: 12),



                        const Text(

                          'Enter your email address and we will send\nyou a code to reset your password.',

                          textAlign: TextAlign.center,

                          style: TextStyle(

                            color: Colors.white70,

                            fontSize: 13,

                            height: 1.4,

                          ),

                        ),



                        const SizedBox(height: 40),



                        const Align(

                          alignment: Alignment.centerLeft,

                          child: Text(

                            'Email Address',

                            style: TextStyle(

                              color: Colors.white,

                              fontSize: 16,

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                        ),



                        const SizedBox(height: 10),



                        NeonTextField(

                          controller: _emailController,

                          hintText: 'Enter your email address',

                          prefixIcon: AppAssets.user2,

                          keyboardType: TextInputType.emailAddress,

                        ),



                        const SizedBox(height: 40),



                        // ... baki imports same ...



                        // GetStartedButton ke andar onComplete ko replace karein:

                        GetStartedButton(

                          text: 'RESET PASSWORD',

                          isLoading: isLoading,

                          onComplete: () async {

                            final email = _emailController.text.trim();

                            // Check real-time validation errors instead of duplicate validation
                            if (_emailError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_emailError!)),
                              );
                              return false;
                            }



                            // ✅ LOADER START 🔥
                            setState(() => isLoading = true);



                            try {

                              await _service.sendResetLink(email: email);



                              // ✅ LOADER STOP

                              setState(() => isLoading = false);



                              if (!mounted) return false;

                              Navigator.push(

                                context,

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

                                      Navigator.push(

                                        context,

                                        MaterialPageRoute(

                                          builder: (_) => ResetPasswordScreen(),

                                        ),

                                      );

                                    },

                                  ),

                                ),

                              );



                              return true;

                            } catch (e) {

                              // ✅ LOADER STOP ON ERROR

                              setState(() => isLoading = false);



                              ScaffoldMessenger.of(context).showSnackBar(

                                SnackBar(

                                  content: Text("Error: ${e.toString()}"),

                                ),

                              );



                              return false;

                            }

                          },

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

