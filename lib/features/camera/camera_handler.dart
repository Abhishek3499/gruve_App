import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/screen/camera_screen.dart';

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
        // Camera successfully captured image
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // TODO: Handle the captured image (e.g., navigate to editor, upload, etc.)
        debugPrint('Image captured at: $imagePath');
      } else {
        // User cancelled camera
        debugPrint('Camera cancelled by user');
      }
    } catch (e) {
      // Handle any errors
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
