import 'package:flutter/material.dart';

import 'package:gruve_app/features/auth/presentation/controller/verifyotp_controller.dart';
import 'package:gruve_app/features/auth/data/datasource/verify_otp_service.dart';

import 'package:sms_autofill/sms_autofill.dart';

import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/shared/widgets/get_started_button.dart';

import 'package:gruve_app/shared/widgets/video_background.dart';

import 'package:gruve_app/features/auth/presentation/widgets/otp_input_box.dart';

import 'package:gruve_app/main.dart';

import 'package:gruve_app/features/auth/presentation/controller/auth_session_helper.dart';
import 'package:gruve_app/features/auth/presentation/controller/auth_ui_provider.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class OtpScreen extends StatefulWidget {
  // final AuthFlow authFlow;

  final String title;

  final String description;

  final String buttonText;

  final Function(String token)? onVerifiedWithToken; // 👈 NEW

  final VoidCallback? onVerified; // 👈 OLD (SAFE)

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

    this.onVerified,

    this.onVerifiedWithToken,

    this.isLogin = false,

    this.isForgot = false,

    // required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill, RouteAware {
  final VerifyotpController controller = VerifyotpController();
  final GetStartedButtonController _otpButtonController =
      GetStartedButtonController();

  final List<TextEditingController> _controllers = List.generate(
    4,

    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _allowSignupOtpPop = false;

  bool get _blocksSystemBack => !widget.isLogin && !widget.isForgot;

  String get _otpPurpose {
    if (widget.isForgot) return OtpPurpose.resetPassword;
    if (widget.isLogin) return OtpPurpose.login;
    return OtpPurpose.signup;
  }

  void _popFromOtp() {
    if (!_blocksSystemBack) {
      Navigator.pop(context);
      return;
    }

    setState(() => _allowSignupOtpPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetOtp();
    });

    listenForCode();

    _focusNodes.first.requestFocus();

    AppLogger.d("🔥 OTP SCREEN INIT");

    AppLogger.d("👉 isForgot: ${widget.isForgot}");

    AppLogger.d("👉 type: ${widget.type}");

    AppLogger.d("👉 identifier: ${widget.identifier}");
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

  void _setOtpDigit(int index, String digit) {
    final value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
    if (_controllers[index].value != value) {
      _controllers[index].value = value;
    }
  }

  void _handleOtpChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return;
    }

    if (digits.length == 1) {
      _setOtpDigit(index, digits);
      if (index < _focusNodes.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].requestFocus();
      }
      return;
    }

    var writeIndex = index;
    for (
      var i = 0;
      i < digits.length && writeIndex < _controllers.length;
      i++
    ) {
      _setOtpDigit(writeIndex, digits[i]);
      writeIndex++;
    }

    final nextEmptyIndex = _controllers.indexWhere(
      (controller) => controller.text.isEmpty,
    );

    if (nextEmptyIndex != -1) {
      _focusNodes[nextEmptyIndex].requestFocus();
    } else {
      _focusNodes.last.requestFocus();
    }
  }

  void _handleOtpBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    final authUi = context.read<AuthUiProvider>();
    if (authUi.isLoading(AuthLoadingKey.resendOtp)) return;

    authUi.setLoading(AuthLoadingKey.resendOtp, true);

    String purpose = OtpPurpose.signup;
    if (widget.isForgot) {
      purpose = OtpPurpose.resetPassword;
    } else if (widget.isLogin) {
      purpose = OtpPurpose.login;
    }

    try {
      final success = await controller.resendOtp(
        identifier: widget.identifier,
        purpose: purpose,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("OTP has been resent successfully.")),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(controller.errorMessage ?? "Failed to resend OTP"),
            ),
          );
      }
    } finally {
      if (mounted) {
        authUi.setLoading(AuthLoadingKey.resendOtp, false);
      }
    }
  }

  void _clearOtpFields() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted && _focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  Future<bool> _verifyOtpManually() async {
    final authUi = context.read<AuthUiProvider>();
    if (authUi.isLoading(AuthLoadingKey.otp)) return false;

    final otp = _controllers.map((e) => e.text).join();

    AppLogger.d("OTP entered");

    final otpError = SignupValidator.validateOtpRealTime(otp);
    if (otpError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(otpError)));
      _clearOtpFields();
      return false;
    }

    FocusScope.of(context).unfocus();

    authUi.setLoading(AuthLoadingKey.otp, true);

    AppLogger.d('🟡 BEFORE API CALL');
    AppLogger.d('👉 purpose: $_otpPurpose');
    AppLogger.d('📡 CALLING CONTROLLER...');

    try {
      await controller.verifyOtp(
        identifier: widget.identifier,
        otp: otp,
        purpose: _otpPurpose,
      );
    } finally {
      if (mounted) {
        authUi.setLoading(AuthLoadingKey.otp, false);
      }
    }

    if (!mounted) return false;

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      _clearOtpFields();
      return false;
    }

    if (controller.verifyOtpResponse?.success == true) {
      if (widget.isForgot) {
        final token = controller.verifyOtpResponse?.resetToken ?? otp;

        if (widget.onVerifiedWithToken != null) {
          widget.onVerifiedWithToken!(token);
        } else {
          AppLogger.d("⚠️ onVerifiedWithToken is null");
        }
      } else {
        if (widget.onVerified != null) {
          widget.onVerified!();
        }

        final accessToken = controller.verifyOtpResponse?.data?.accessToken;
        if (accessToken != null && accessToken.isNotEmpty && mounted) {
          if (widget.isLogin) {
            AuthSessionHelper.bootstrapAfterLogin(context, accessToken);
          } else {
            AuthSessionHelper.connectSocket(accessToken);
          }
        }
      }

      return true;
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              controller.verifyOtpResponse?.message ?? "Invalid OTP",
            ),
          ),
        );
      _clearOtpFields();
      return false;
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
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.otp),
    );
    final isResending = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.resendOtp),
    );

    return PopScope(
      canPop: !_blocksSystemBack || _allowSignupOtpPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _blocksSystemBack) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,

        body: VideoBackground(
          videoPath: AppAssets.splashVideo,

          overlayOpacity: 0.85,

          child: SafeArea(
            child: Column(
              children: [
                // 🔹 Top Bar (Fixed Progress Bar Width)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(24),

                    vertical: context.rh(16),
                  ),

                  child: Row(
                    children: [
                      BackButton(
                        color: Colors.white,
                        onPressed: _popFromOtp,
                      ),

                      SizedBox(width: context.rw(55)),

                      // Progress Bar with Fixed Width
                      SizedBox(
                        width: context.rw(210), // ✅ Width yahan se control karein

                        child: Container(
                          height: context.rh(9),

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
                SizedBox(height: context.rh(100)),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.rw(24)),

                    child: SingleChildScrollView(
                      // Added scroll to prevent overflow on small screens
                      child: Column(
                        children: [
                          SizedBox(height: context.rh(60)),

                          FittedBox(
                            fit: BoxFit.scaleDown,

                            child: RichText(
                              textAlign: TextAlign.center,

                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.white,

                                  fontSize: context.rf(28),

                                  fontWeight: FontWeight.bold,

                                  letterSpacing: 1.0,

                                  fontFamily: AppAssets.syncopateFont,
                                ),

                                children: const [
                                  TextSpan(text: 'Enter your '),

                                  TextSpan(
                                    text: 'Code ',

                                    style: TextStyle(color: Color(0xFFB86AD0)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: context.rh(12)),

                          Text(
                            "Enter 4-digit code we have sent to you at",

                            textAlign: TextAlign.center,

                            style: TextStyle(color: Colors.white, fontSize: context.rf(13)),
                          ),

                          SizedBox(height: context.rh(10)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Text(
                                widget.type == "phone"
                                    ? _maskPhoneNumber(widget.identifier)
                                    : widget.identifier,

                                style: TextStyle(
                                  color: const Color(0xFFB86AD0),

                                  fontSize: context.rf(14),

                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(width: context.rw(8)),

                              GestureDetector(
                                onTap: _popFromOtp,

                                child: Icon(
                                  Icons.edit,

                                  color: const Color(0xFFB86AD0),

                                  size: context.rw(16),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: context.rh(40)),

                          // OTP Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                            children: List.generate(4, (i) {
                              return OtpInputBox(
                                controller: _controllers[i],

                                focusNode: _focusNodes[i],

                                autoFocus: i == 0,
                                enableSmsAutofill: i == 0,
                                textInputAction: i == _controllers.length - 1
                                    ? TextInputAction.done
                                    : TextInputAction.next,

                                onChanged: (val) => _handleOtpChanged(i, val),

                                onBackspace: () => _handleOtpBackspace(i),
                                onSubmitted: (_) {
                                  if (i == _controllers.length - 1) {
                                    _otpButtonController.submit();
                                  }
                                },
                              );
                            }),
                          ),

                          Align(
                            alignment: Alignment.centerRight,

                            child: TextButton(
                              onPressed: (isLoading || isResending) ? null : _resendOtp,

                              child: isResending
                                  ? SizedBox(
                                      height: context.rh(16),
                                      width: context.rw(16),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFBB86FC),
                                            ),
                                      ),
                                    )
                                  : Text(
                                      "Resend code",

                                      style: TextStyle(
                                        color: const Color(0xFFB86AD0),

                                        fontSize: context.rf(12),
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: context.rh(40)),

                          GetStartedButton(
                            controller: _otpButtonController,

                            text: widget.buttonText,

                            isLoading: isLoading,

                            onComplete: _verifyOtpManually,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
