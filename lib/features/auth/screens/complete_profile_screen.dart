import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/widgets/get_started_button.dart';
import 'package:gruve_app/core/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/core/widgets/video_background.dart';
import 'package:gruve_app/features/auth/api/controllers/complete_profile_controller.dart';
import 'package:gruve_app/features/auth/presentation/provider/auth_ui_provider.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/services/image_picker_service.dart';
import 'package:provider/provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final CompleteProfileController controller = CompleteProfileController();
  final TextEditingController _usernameController = TextEditingController();

  String? _usernameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetCompleteProfile();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateCompleteProfile() {
    final authUi = context.read<AuthUiProvider>();
    final selectedImage = authUi.selectedProfileImage;
    final username = _usernameController.text.trim();
    final usernameError = SignupValidator.validateUsernameRealTime(username);

    setState(() => _usernameError = usernameError);

    if (selectedImage == null || selectedImage.path.trim().isEmpty) {
      _showSnackBar('Please add profile image');
      return false;
    }

    if (usernameError != null) {
      _showSnackBar(username.isEmpty ? 'Please enter username' : usernameError);
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
          _showSnackBar('Please choose a valid profile image');
          return;
        }

        final bytes = await image.readAsBytes();
        if (!mounted) return;

        if (bytes.isEmpty) {
          _showSnackBar('Selected profile image is empty');
          return;
        }

        context.read<AuthUiProvider>().setProfileImage(image, bytes);
      },
    );
  }

  Future<bool> _completeProfile() async {
    if (!_validateCompleteProfile()) return false;

    final authUi = context.read<AuthUiProvider>();
    final selectedImage = authUi.selectedProfileImage;
    final username = _usernameController.text.trim();
    final file = selectedImage?.path;

    debugPrint("USERNAME: '$username'");
    debugPrint("IMAGE PATH: '$file'");

    authUi.setLoading(AuthLoadingKey.completeProfile, true);
    try {
      await controller.completeProfile(
        username: username,
        file: file,
        image: selectedImage,
      );
    } finally {
      if (mounted) {
        context
            .read<AuthUiProvider>()
            .setLoading(AuthLoadingKey.completeProfile, false);
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
    final authUi = context.watch<AuthUiProvider>();
    final selectedImage = authUi.selectedProfileImage;
    final selectedImageBytes = authUi.selectedProfileImageBytes;
    final isLoading = authUi.isLoading(AuthLoadingKey.completeProfile);

    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppAssets.syncopateFont,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: 'Complete '),
                          TextSpan(
                            text: 'Profile',
                            style: TextStyle(color: Color(0xFFB86AD0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.purple,
                      backgroundImage: selectedImageBytes != null
                          ? MemoryImage(selectedImageBytes)
                          : null,
                      child: selectedImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 40),
                  NeonTextField(
                    controller: _usernameController,
                    hintText: 'Enter your username',
                    prefixIcon: AppAssets.user2,
                    onChanged: (value) {
                      if (_usernameError == null) return;
                      setState(() {
                        _usernameError =
                            SignupValidator.validateUsernameRealTime(value);
                      });
                    },
                  ),
                  if (_usernameError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _usernameError!,
                          style: const TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  GetStartedButton(
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
