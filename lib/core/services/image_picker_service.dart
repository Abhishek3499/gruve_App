import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ImagePickerService {
  static final ImagePicker _imagePicker = ImagePicker();
  static bool _androidPickerConfigured = false;

  static void _configureAndroidPicker() {
    if (_androidPickerConfigured) return;

    final implementation = ImagePickerPlatform.instance;
    if (implementation is ImagePickerAndroid) {
      implementation.useAndroidPhotoPicker = true;
    }

    _androidPickerConfigured = true;
  }

  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<XFile?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        AppLogger.d('Camera permission denied');
        return null;
      }

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );

      AppLogger.d('Camera image picked: ${image?.path}');
      return image;
    } catch (e) {
      AppLogger.d('Error picking image from camera: $e');
      return null;
    }
  }

  static Future<XFile?> pickMediaFromGallery() async {
    try {
      _configureAndroidPicker();

      final media = await _imagePicker.pickMedia(
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      AppLogger.d('Gallery media picked: ${media?.path}');
      return media;
    } catch (e) {
      AppLogger.d('Error picking media from gallery: $e');
      return null;
    }
  }

  static Future<XFile?> pickImageFromGallery() async {
    try {
      _configureAndroidPicker();

      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      AppLogger.d('Gallery image picked: ${image?.path}');
      return image;
    } catch (e) {
      AppLogger.d('Error picking image from gallery: $e');
      return null;
    }
  }

  static void showImagePickerBottomSheet(
    BuildContext context, {
    required Function(XFile) onImageSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2C1B3D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Select Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ImagePickerOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 120),
                        );
                        final image = await pickImageFromCamera();
                        if (image != null) {
                          onImageSelected(image);
                        } else {
                          AppLogger.d(
                            'Camera image selection cancelled or failed',
                          );
                        }
                      },
                    ),
                    _ImagePickerOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 120),
                        );
                        final image = await pickImageFromGallery();
                        if (image != null) {
                          onImageSelected(image);
                        } else {
                          AppLogger.d(
                            'Gallery image selection cancelled or failed',
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF461851),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFAF50C4), width: 1),
            ),
            child: Icon(icon, color: Colors.white70, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
