import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth_flow.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/screens/auth/widgets/otp_input_box.dart';

import 'package:gruve_app/main.dart';

class OtpScreen extends StatefulWidget {
  final AuthFlow authFlow;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onVerified;

  const OtpScreen({
    super.key,
    required this.authFlow,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill, RouteAware {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    listenForCode(); // ✅ SMS auto listen
    _focusNodes.first.requestFocus();

    for (final controller in _controllers) {
      controller.addListener(_checkOtpComplete);
    }
  }

  @override
  void codeUpdated() {
    if (code == null || code!.length < 4) return;

    // ✅ Auto-fill OTP
    for (int i = 0; i < 4; i++) {
      _controllers[i].text = code![i];
    }

    // ✅ Move focus to last field
    _focusNodes.last.requestFocus();

    // ✅ Check completion
    _checkOtpComplete();
  }

  void _checkOtpComplete() {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length == 4) {
      FocusScope.of(context).unfocus();

      // 🔥 AUTO NAVIGATION
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onVerified();
      });
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
    cancel(); // stop listening sms
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// 🔥 Reset OTP fields when coming back
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
      backgroundColor: Colors.transparent,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          fontFamily: AppAssets.syncopateFont,
                        ),
                        children: [
                          TextSpan(text: 'Enter your '),
                          TextSpan(
                            text: 'Code ',
                            style: TextStyle(
                              color: Color(0xFFB86AD0),
                              fontFamily: 'syncopate',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                  const SizedBox(height: 40),

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
                          _checkOtpComplete();
                        },
                        onBackspace: () {
                          if (i > 0 && _controllers[i].text.isEmpty) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          _checkOtpComplete();
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 40),

                  // 🔹 fallback button (optional)
                  GetStartedButton(
                    text: widget.buttonText,
                    onComplete: widget.onVerified,
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
