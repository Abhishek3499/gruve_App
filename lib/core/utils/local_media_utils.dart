import 'dart:io';

import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:video_player/video_player.dart';

enum LocalMediaKind { image, video, unknown }

/// Detects whether a local file path is an image or video.
/// Android/iOS gallery picks often omit file extensions — mime + probe fallback.
class LocalMediaUtils {
  LocalMediaUtils._();

  static const _imageExtensions = <String>[
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
    '.bmp',
  ];

  static const _videoExtensions = <String>[
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
    '.m4v',
    '.3gp',
    '.3gpp',
    '.mpeg',
    '.mpg',
    '.m3u8',
  ];

  static String _pathOnly(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    return (uri?.path ?? trimmed).toLowerCase();
  }

  static bool mimeLooksLikeVideo(String? mimeType) {
    final mime = mimeType?.toLowerCase().trim();
    return mime != null && mime.isNotEmpty && mime.startsWith('video/');
  }

  static bool mimeLooksLikeImage(String? mimeType) {
    final mime = mimeType?.toLowerCase().trim();
    return mime != null && mime.isNotEmpty && mime.startsWith('image/');
  }

  static bool isImagePath(String path, {String? mimeType}) {
    if (mimeLooksLikeImage(mimeType)) return true;
    final lower = _pathOnly(path);
    return _imageExtensions.any(lower.endsWith);
  }

  static bool isVideoPath(String path, {String? mimeType}) {
    if (mimeLooksLikeVideo(mimeType)) return true;
    final lower = _pathOnly(path);
    if (_videoExtensions.any(lower.endsWith)) return true;
    return Post.mediaUrlLooksLikeVideo(path);
  }

  static Future<VideoPlayerController?> createInitializedVideoController(
    String path,
  ) async {
    final file = File(path);
    if (!file.existsSync()) return null;

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      return controller;
    } catch (_) {
      await controller.dispose();
      return null;
    }
  }

  /// Resolves local media kind. Probes with [VideoPlayerController] when path
  /// has no extension (common for gallery picks on Android).
  static Future<LocalMediaKind> resolveKind(
    String path, {
    String? mimeType,
  }) async {
    final result = await resolveForPreview(path, mimeType: mimeType);
    result.controller?.dispose();
    return result.kind;
  }

  static Future<({LocalMediaKind kind, VideoPlayerController? controller})>
  resolveForPreview(
    String path, {
    String? mimeType,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return (kind: LocalMediaKind.unknown, controller: null);
    }

    final image = isImagePath(trimmed, mimeType: mimeType);
    final video = isVideoPath(trimmed, mimeType: mimeType);

    if (image && !video) {
      return (kind: LocalMediaKind.image, controller: null);
    }

    if (video || !image) {
      final controller = await createInitializedVideoController(trimmed);
      if (controller != null) {
        return (kind: LocalMediaKind.video, controller: controller);
      }
      if (video) {
        return (kind: LocalMediaKind.video, controller: null);
      }
    }

    return (kind: LocalMediaKind.image, controller: null);
  }

  /// Reliable detection before upload. Gallery picks often omit extensions;
  /// misclassifying video as image runs JPEG compression and corrupts the file.
  static Future<bool> isVideoForUpload(
    String path, {
    String? mimeType,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;

    if (mimeLooksLikeVideo(mimeType)) return true;
    if (mimeLooksLikeImage(mimeType) && !mimeLooksLikeVideo(mimeType)) {
      return false;
    }

    final videoByPath = isVideoPath(trimmed, mimeType: mimeType);
    final imageByPath = isImagePath(trimmed, mimeType: mimeType);

    if (videoByPath && !imageByPath) return true;
    if (imageByPath && !videoByPath) return false;

    AppLogger.d('[LocalMediaUtils] Probing upload media kind: $trimmed');
    final kind = await resolveKind(trimmed, mimeType: mimeType);
    AppLogger.d('[LocalMediaUtils] Upload probe => $kind');
    return kind == LocalMediaKind.video;
  }

  static String uploadFilename(String path, {required bool isVideo}) {
    final base = path.replaceAll(r'\', '/').split('/').last;
    if (!isVideo) return base.isEmpty ? 'upload.jpg' : base;

    final lower = base.toLowerCase();
    if (_videoExtensions.any(lower.endsWith)) return base;
    return base.isEmpty ? 'upload.mp4' : '$base.mp4';
  }
}
