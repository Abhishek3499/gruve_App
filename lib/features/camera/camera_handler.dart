import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/screen/camera_screen.dart';
import 'package:gruve_app/features/story_preview/screens/story_preview_screen.dart';

class CameraHandler {
  /// Opens custom camera screen instead of native camera
  /// This removes the movable capture circle from native camera
  static Future<void> openCamera(BuildContext context) async {
    try {
      final String? imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraScreen(),
        ),
      );

      if (imagePath != null && imagePath.isNotEmpty) {
        // Camera successfully captured image, navigate to story preview
        debugPrint('Image captured at: $imagePath');
        
        // Navigate to story preview with the captured image
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryPreviewScreen(mediaPath: imagePath),
            ),
          );
        }
      } else {
        // User cancelled camera
        debugPrint('Camera cancelled by user');
      }
    } catch (e) {
      // Handle any errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening camera: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
