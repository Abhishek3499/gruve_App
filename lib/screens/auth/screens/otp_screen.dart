import 'package:flutter/material.dart';
import '../api/controllers/verifyotp_controller.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/screens/auth/widgets/otp_input_box.dart';
import 'package:gruve_app/main.dart';

class OtpScreen extends StatefulWidget {
  // final AuthFlow authFlow;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onVerified;

  // final String phoneNumber;
  final String identifier; // email ya phone
  final String type;
  final bool isLogin;
  final bool isForgot;

  const OtpScreen({
    super.key,
    required this.identifier,
    required this.type,
    // required this.authFlow,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onVerified,

    this.isLogin = false,
    this.isForgot = false,
    // required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill, RouteAware {
  final VerifyotpController controller = VerifyotpController();
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool isLoading = false;
  // Mask phone number function (crash-proof)
  String _maskPhoneNumber(String phone) {
    if (phone.isEmpty) return phone;

    // Remove spaces for processing
    String cleaned = phone.replaceAll(' ', '');

    // Safety check — if too short, return as is
    if (cleaned.length < 6) return phone;

    // Last 4 digits always visible
    String lastFour = cleaned.substring(cleaned.length - 4);

    // Middle digits — everything between first 2 and last 4
    int middleLength = cleaned.length - 6;
    String middle = middleLength > 0
        ? List.filled(middleLength, 'x').join()
        : '';

    // First 2 digits always visible
    String firstTwo = cleaned.substring(0, 2);

    // Final result: 98xxxxx8282 style
    return '$firstTwo$middle$lastFour';
  }

  @override
  void initState() {
    super.initState();
    listenForCode();
    _focusNodes.first.requestFocus();
  }

  @override
  void codeUpdated() {
    if (code == null) return;

    final otp = code!.toString();

    // ✅ safety check
    if (otp.length < 4) return;

    for (int i = 0; i < 4; i++) {
      _controllers[i].text = otp[i]; // ✅ safe indexing
    }

    _focusNodes.last.requestFocus();
  }

  Future<void> _verifyOtpManually() async {
    final otp = _controllers.map((e) => e.text).join();

    // ✅ VALIDATION
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete OTP")),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    await controller.verifyOtp(
      identifier: widget.identifier,
      type: widget.type,
      otp: otp,
      isLogin: widget.isLogin,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      return;
    }

    if (controller.verifyOtpResponse?.success == true) {
      widget.onVerified(); // ✅ ONLY SUCCESS NAVIGATION
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.verifyOtpResponse?.message ?? "Invalid OTP"),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Top Bar (Fixed Progress Bar Width)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(AppAssets.back, height: 25, width: 25),
                    ),
                    const SizedBox(width: 55),
                    // Progress Bar with Fixed Width
                    SizedBox(
                      width: 210, // ✅ Width yahan se control karein
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.2, // 20% progress
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFB86AD0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Content Area
              const SizedBox(height: 100),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    // Added scroll to prevent overflow on small screens
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                fontFamily: AppAssets.syncopateFont,
                              ),
                              children: [
                                TextSpan(text: 'Enter your '),
                                TextSpan(
                                  text: 'Code ',
                                  style: TextStyle(color: Color(0xFFB86AD0)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Enter 4-digit code we have sent to you at",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.type == "phone"
                                  ? _maskPhoneNumber(widget.identifier)
                                  : widget.identifier,
                              style: const TextStyle(
                                color: Color(0xFFB86AD0),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.edit,
                                color: Color(0xFFB86AD0),
                                size: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // OTP Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (i) {
                            return OtpInputBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              autoFocus: i == 0,
                              onChanged: (val) {
                                if (val.isNotEmpty && i < 3) {
                                  _focusNodes[i + 1].requestFocus();
                                }
                              },
                              onBackspace: () {
                                if (i > 0 && _controllers[i].text.isEmpty) {
                                  _focusNodes[i - 1].requestFocus();
                                }
                              },
                            );
                          }),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Resend code",
                              style: TextStyle(
                                color: Color(0xFFB86AD0),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        GetStartedButton(
                          text: widget.buttonText,
                          onComplete: _verifyOtpManually,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
