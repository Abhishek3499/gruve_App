import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/api/controllers/complete_profile_controller.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/services/image_picker_service.dart';
import 'package:gruve_app/screens/auth/presentation/provider/auth_ui_provider.dart';
import 'package:provider/provider.dart';

// ✅ IMPORT

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final CompleteProfileController controller =
      CompleteProfileController(); // ✅ FIX

  final TextEditingController _usernameController =
      TextEditingController(); // ✅ FIX

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthUiProvider>().resetCompleteProfile();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose(); // ✅ FIX
    super.dispose();
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

                  const SizedBox(height: 40),

                  const SizedBox(height: 40),

                  // 🔥 IMAGE PICKER
                  GestureDetector(
                    onTap: () {
                      ImagePickerService.showImagePickerBottomSheet(
                        context,
                        onImageSelected: (image) async {
                          final bytes = await image.readAsBytes();
                          if (!mounted) return;
                          context.read<AuthUiProvider>().setProfileImage(
                            image,
                            bytes,
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.purple,
                      backgroundImage: selectedImageBytes != null &&
                              !authUi.isSelectedProfileMediaVideo
                          ? MemoryImage(selectedImageBytes)
                          : null,
                      child: selectedImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.white)
                          : authUi.isSelectedProfileMediaVideo
                          ? const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔥 USERNAME FIELD
                  NeonTextField(
                    controller: _usernameController, // ✅ FIX
                    hintText: 'Enter your username',
                    prefixIcon: AppAssets.user2,
                  ),

                  const SizedBox(height: 40),

                  // 🔥 BUTTON
                  GetStartedButton(
                    text: 'Complete',
                    isLoading: isLoading,
                    onComplete: () async {
                      final username = _usernameController.text.trim();
                      final file = selectedImage?.path;
                      debugPrint("USERNAME: '$username'");
                      debugPrint("IMAGE PATH: '$file'");

                      if (username.isEmpty &&
                          (file == null || file.trim().isEmpty)) {
                        if (!context.mounted) return false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a username or choose a profile photo.',
                            ),
                          ),
                        );
                        return false;
                      }

                      context.read<AuthUiProvider>().setLoading(
                        AuthLoadingKey.completeProfile,
                        true,
                      );
                      try {
                        await controller.completeProfile(
                          username: username,
                          file: file,
                          image: selectedImage,
                        );
                      } finally {
                        context.read<AuthUiProvider>().setLoading(
                          AuthLoadingKey.completeProfile,
                          false,
                        );
                      }

                      if (!context.mounted) return false;

                      if (controller.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(controller.errorMessage!)),
                        );
                        return false;
                      }

                      if (controller.response == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Profile could not be saved. Please try again.',
                            ),
                          ),
                        );
                        return false;
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                      return true;
                    },
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
