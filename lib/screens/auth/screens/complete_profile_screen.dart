import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/api/controllers/complete_profile_controller.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/services/image_picker_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ✅ IMPORT

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  XFile? _selectedImage;

  final CompleteProfileController controller =
      CompleteProfileController(); // ✅ FIX

  final TextEditingController _usernameController =
      TextEditingController(); // ✅ FIX

  @override
  void dispose() {
    _usernameController.dispose(); // ✅ FIX
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 120),

                const Text(
                  "Complete Profile",
                  style: TextStyle(color: Colors.white, fontSize: 26),
                ),

                const SizedBox(height: 40),

                // 🔥 IMAGE PICKER
                GestureDetector(
                  onTap: () {
                    ImagePickerService.showImagePickerBottomSheet(
                      context,
                      onImageSelected: (image) {
                        setState(() {
                          _selectedImage = image;
                        });
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.purple,
                    backgroundImage: _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : null,
                    child: _selectedImage == null
                        ? const Icon(Icons.camera_alt, color: Colors.white)
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
                  onComplete: () async {
                    await controller.completeProfile(
                      username: _usernameController.text.trim(),
                      imagePath: _selectedImage?.path,
                    );

                    if (!context.mounted) return false;

                    if (controller.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(controller.errorMessage!)),
                      );
                      return false;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                    return true;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
