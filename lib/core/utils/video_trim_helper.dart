import 'dart:async';
import 'dart:io';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VideoTrimHelper {
  VideoTrimHelper._();

  /// Trims a video file programmatically using native platform trimmers.
  /// Returns the path to the trimmed video file, or null if the operation fails.
  static Future<String?> trimVideo({
    required String originalPath,
    required double startMs,
    required double endMs,
  }) async {
    try {
      final originalFile = File(originalPath);
      if (!originalFile.existsSync()) {
        AppLogger.d('❌ [VideoTrimHelper] Original file does not exist: $originalPath');
        return null;
      }

      final trimmer = Trimmer();
      AppLogger.d('🎬 [VideoTrimHelper] Loading video for trimming: $originalPath');
      await trimmer.loadVideo(videoFile: originalFile);

      String? trimmedPath;
      final completer = Completer<String?>();

      AppLogger.d('🎬 [VideoTrimHelper] Saving trimmed video from $startMs to $endMs ms...');
      await trimmer.saveTrimmedVideo(
        startValue: startMs,
        endValue: endMs,
        onSave: (outputPath) {
          trimmedPath = outputPath;
          completer.complete(outputPath);
        },
      );

      // Wait for onSave callback to complete
      await completer.future;

      if (trimmedPath != null) {
        AppLogger.d('🎬 [VideoTrimHelper] Video trimmed successfully: $trimmedPath');
        try {
          final rawFile = File(trimmedPath!);
          if (rawFile.existsSync()) {
            final directoryPath = rawFile.parent.path;
            final originalName = rawFile.path.replaceAll(r'\', '/').split('/').last;

            final extensionIndex = originalName.lastIndexOf('.');
            final nameWithoutExt = extensionIndex != -1 ? originalName.substring(0, extensionIndex) : originalName;
            final ext = extensionIndex != -1 ? originalName.substring(extensionIndex) : '';

            final sanitizedName = nameWithoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_') + ext;
            final safePath = '$directoryPath/$sanitizedName';

            AppLogger.d('🎬 [VideoTrimHelper] Renaming trimmed video to safe path: $safePath');
            final safeFile = await rawFile.rename(safePath);
            if (safeFile.existsSync()) {
              AppLogger.d('🎬 [VideoTrimHelper] Cleaned/Safe trimmed file path exists: ${safeFile.path}');
              return safeFile.path;
            }
          }
        } catch (renameError) {
          AppLogger.d('⚠️ [VideoTrimHelper] Renaming failed, returning raw trimmedPath: $renameError');
        }
        return trimmedPath;
      } else {
        AppLogger.d('❌ [VideoTrimHelper] Trim completed but output path is null');
        return null;
      }
    } catch (e) {
      AppLogger.d('❌ [VideoTrimHelper] Error trimming video: $e');
      return null;
    }
  }
}
