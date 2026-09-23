import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:gruve_app/features/camera/utils/camera_logger.dart';

/// Re-encodes a recorded video to play back at [speed]x.
class VideoSpeedProcessor {
  /// Returns the path of a video re-encoded to [speed]x.
  /// Returns [inputPath] unchanged if [speed] is 1x or processing fails.
  static Future<String> applySpeed(String inputPath, double speed) async {
    if (speed == 1.0) return inputPath;

    try {
      final outputPath = await VideoEditorBuilder(
        videoPath: inputPath,
      ).speed(speed: speed).export();
      return outputPath ?? inputPath;
    } catch (e) {
      CameraLogger.log('Failed to apply ${speed}x speed: $e');
      return inputPath;
    }
  }
}
