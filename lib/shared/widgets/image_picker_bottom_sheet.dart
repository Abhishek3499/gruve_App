import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gruve_app/core/services/image_picker_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Bottom sheet offering "Camera" / "Gallery" as an image source, wired to
/// [ImagePickerService]. Colors here are one-off to this sheet and aren't
/// yet part of the shared palette in app_colors.dart.
class ImagePickerBottomSheet {
  ImagePickerBottomSheet._();

  static void show(
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
                        final image =
                            await ImagePickerService.pickImageFromCamera();
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
                        final image =
                            await ImagePickerService.pickImageFromGallery();
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
