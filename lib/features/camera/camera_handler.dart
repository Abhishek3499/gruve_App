import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/screen/camera_screen.dart';
import 'package:gruve_app/features/camera/services/mode_service.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/story_preview/screens/post/post_preview_navigation.dart';
import 'package:gruve_app/features/story_preview/screens/post/post_preview_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/share_post_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/share_post_sheet.dart';
import 'package:gruve_app/features/story_preview/screens/story_preview_screen.dart';

class CameraHandler {
  static Future<dynamic> openCamera(BuildContext context) async {
    try {
      final CameraCaptureResult? capture =
          await Navigator.push<CameraCaptureResult>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );

      final imagePath = capture?.mediaPath;
      final captureMode = capture?.mode;

      if (imagePath != null &&
          imagePath.isNotEmpty &&
          captureMode != null &&
          context.mounted) {
        // Mode labels in UI: Story / Gruve (groove). Route by mode at capture time.
        if (captureMode == CameraMode.story) {
          final storyResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryPreviewScreen(mediaPath: imagePath),
            ),
          );
          return storyResult;
        }
        if (captureMode == CameraMode.groove) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostPreviewScreen(mediaPath: imagePath),
            ),
          );

          if (!context.mounted) return null;

          if (result is PostPreviewOpenShare) {
            Navigator.of(context).pop();
            await Future<void>.delayed(Duration.zero);
            if (!context.mounted) return null;
            return showSharePostOnHomeSheet(result.mediaPath);
          }

          if (result != null && result is List<ChatUser>) {
            final shareResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SharePostScreen(
                  mediaPath: imagePath,
                  taggedUsers: result,
                ),
              ),
            );
            return shareResult;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error opening camera: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }
}