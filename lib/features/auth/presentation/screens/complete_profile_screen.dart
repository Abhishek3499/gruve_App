import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/shared/widgets/get_started_button.dart';
import 'package:gruve_app/shared/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/shared/widgets/video_background.dart';
import 'package:gruve_app/features/auth/presentation/controller/complete_profile_controller.dart';
import 'package:gruve_app/features/auth/presentation/controller/auth_ui_provider.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/features/home/presentation/screens/home_screen.dart';
import 'package:gruve_app/core/services/image_picker_service.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final CompleteProfileController controller = CompleteProfileController();
  final GetStartedButtonController _completeButtonController =
      GetStartedButtonController();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();

  bool _usernameTouched = false;
  bool _profileImageTouched = false;
  String? _profileImageError;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetCompleteProfile();
    });

    _usernameController.addListener(() {
      final error = SignupValidator.validateUsernameRealTime(_usernameController.text);
      if (mounted) {
        setState(() {
          _usernameError = error;
        });
      }
    });


  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateCompleteProfile() {
    if (mounted) {
      setState(() {
        _usernameTouched = true;
        _profileImageTouched = true;
      });
    }

    final authUi = context.read<AuthUiProvider>();
    final selectedImage = authUi.selectedProfileImage;
    final username = _usernameController.text.trim();
    final usernameError = SignupValidator.validateUsernameRealTime(username);

    final profileImageError =
        selectedImage == null || selectedImage.path.trim().isEmpty
        ? 'Please add a profile photo to continue'
        : null;

    if (mounted) {
      setState(() {
        _profileImageError = profileImageError;
        _usernameError = usernameError;
      });
    }

    if (profileImageError != null) {
      _showSnackBar(profileImageError);
      return false;
    }

    if (usernameError != null) {
      _showSnackBar(
        username.isEmpty ? 'Please enter a username' : usernameError,
      );
      return false;
    }

    return true;
  }

  Future<void> _pickProfileImage() async {
    ImagePickerService.showImagePickerBottomSheet(
      context,
      onImageSelected: (image) async {
        if (image.path.trim().isEmpty) {
          if (!mounted) return;
          _showSnackBar('Please choose a valid profile photo');
          return;
        }

        final bytes = await image.readAsBytes();
        if (!mounted) return;

        if (bytes.isEmpty) {
          _showSnackBar(
            'Selected profile photo is empty. Please choose another image',
          );
          return;
        }

        context.read<AuthUiProvider>().setProfileImage(image, bytes);
        setState(() => _profileImageError = null);
      },
    );
  }

  Future<bool> _completeProfile() async {
    FocusScope.of(context).unfocus();

    if (!_validateCompleteProfile()) return false;

    final authUi = context.read<AuthUiProvider>();
    if (authUi.isLoading(AuthLoadingKey.completeProfile)) return false;
    final selectedImage = authUi.selectedProfileImage;
    final username = _usernameController.text.trim();
    final file = selectedImage?.path;

    AppLogger.d("USERNAME: '$username'");
    AppLogger.d("IMAGE PATH: '$file'");

    authUi.setLoading(AuthLoadingKey.completeProfile, true);
    try {
      await controller.completeProfile(
        username: username,
        file: file,
        image: selectedImage,
      );
    } finally {
      if (mounted) {
        context.read<AuthUiProvider>().setLoading(
          AuthLoadingKey.completeProfile,
          false,
        );
      }
    }

    if (!mounted) return false;

    if (controller.errorMessage != null) {
      _showSnackBar(controller.errorMessage!);
      return false;
    }

    if (controller.response == null) {
      _showSnackBar('Profile could not be saved. Please try again.');
      return false;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final selectedImage = context.select<AuthUiProvider, Object?>(
      (authUi) => authUi.selectedProfileImage,
    );
    final selectedImageBytes = context.select<AuthUiProvider, Uint8List?>(
      (authUi) => authUi.selectedProfileImageBytes,
    );
    final isLoading = context.select<AuthUiProvider, bool>(
      (authUi) => authUi.isLoading(AuthLoadingKey.completeProfile),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
              child: Column(
                children: [
                  SizedBox(height: context.rh(120)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: context.rf(22),
                          fontWeight: FontWeight.w500,
                          fontFamily: AppAssets.syncopateFont,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(text: 'Complete '),
                          TextSpan(
                            text: 'Profile',
                            style: TextStyle(color: Color(0xFFB86AD0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.rh(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lorem Ipsum is simply dummy text of the\nprinting and typesetting industry',

                      textAlign: TextAlign.left,

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: context.rf(14),

                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: context.rh(40)),
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: context.rw(60),
                            backgroundColor: Colors.purple,
                            backgroundImage: selectedImageBytes != null
                                ? MemoryImage(selectedImageBytes)
                                : null,
                            child: selectedImage == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  )
                                : null,
                          ),

                          Positioned(
                            right: 5,
                            bottom: 17,
                            child: Container(
                              height: context.rh(26),
                              width: context.rw(26),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFB026FF),
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.editbutton,
                                  height: context.rh(15),
                                  width: context.rw(15),
                                  color: Colors.white,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: (_profileImageTouched ? _profileImageError : null) != null
                        ? Padding(
                            padding: EdgeInsets.only(top: context.rh(10)),
                            child: Text(
                              _profileImageError!,
                              style: TextStyle(
                                color: const Color(0xFFFF6B6B),
                                fontSize: context.rf(11),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(height: context.rh(40)),
                  NeonTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    hintText: 'Enter your username',
                    prefixIcon: AppAssets.user2,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _completeButtonController.submit(),
                    errorText: _usernameTouched ? _usernameError : null,
                  ),
                  SizedBox(height: context.rh(40)),
                  GetStartedButton(
                    controller: _completeButtonController,
                    text: 'Complete',
                    isLoading: isLoading,
                    onComplete: _completeProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
