import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/services/image_picker_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  XFile? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.18),
                      FittedBox(
                        fit: BoxFit.scaleDown, // 🔥 shrink if needed
                        child: Text.rich(
                          const TextSpan(
                            style: TextStyle(
                              fontFamily:
                                  AppAssets.syncopateFont, // or 'Syncopate'
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.0, // 🔥 line-height: 100%
                              letterSpacing: 0.0, // 🔥 letter-spacing: 0%
                            ),

                            children: [
                              TextSpan(
                                text: 'Complete ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: .w700,
                                ),
                              ),
                              TextSpan(
                                text: 'Profile',
                                style: TextStyle(color: Color(0xFFB86AD0)),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentGeometry.bottomStart,
                        child: const Text(
                          'Lorem Ipsum is simply dummy text of the\n printing and typesetting industry',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: .w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF461851),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(
                                  color: const Color(0xFFAF50C4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  const BoxShadow(
                                    color: Color(0x40000000),
                                    offset: Offset(0, 4),
                                    blurRadius: 20,
                                  ),
                                  const BoxShadow(
                                    color: Color(0xCC5C1B6D),
                                    offset: Offset(-8, -8),
                                    blurRadius: 20,
                                    spreadRadius: -1,
                                  ),
                                ],
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white70,
                                                size: 40,
                                              );
                                            },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                            ),

                            // 👇 Pencil icon (overlay)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 👇 Circle background from AppAssets
                                    Image.asset(
                                      AppAssets.cicle, // your circle image
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    ),

                                    // 👇 Edit icon from AppAssets
                                    Image.asset(
                                      AppAssets.editbutton, // your edit icon
                                      width: 14,
                                      height: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const SizedBox(height: 30),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Username',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      NeonTextField(
                        hintText: 'Enter your username',
                        prefixIcon: AppAssets.user2,
                      ),
                      const SizedBox(height: 40),
                      GetStartedButton(
                        text: 'Completes',
                        onComplete: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                        },
                      ),
                    ],
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
