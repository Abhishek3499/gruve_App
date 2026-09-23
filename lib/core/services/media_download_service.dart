import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Thrown when the device denies access to save into the gallery.
class MediaGalleryAccessDeniedException implements Exception {
  const MediaGalleryAccessDeniedException();
}

class MediaDownloadService {
  static Future<void> downloadVideoToGallery(
    String url, {
    void Function(double progress)? onProgress,
  }) => _downloadToGallery(url, isVideo: true, onProgress: onProgress);

  static Future<void> downloadImageToGallery(
    String url, {
    void Function(double progress)? onProgress,
  }) => _downloadToGallery(url, isVideo: false, onProgress: onProgress);

  static final Dio _downloadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  static Future<void> _downloadToGallery(
    String url, {
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    AppLogger.d('[MediaDownloadService] Checking gallery access...');
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      AppLogger.d('[MediaDownloadService] Requesting gallery access...');
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        throw const MediaGalleryAccessDeniedException();
      }
    }

    final tempDir = await getTemporaryDirectory();
    final extension = _extensionFromUrl(url, isVideo: isVideo);
    final tempFile = File(
      '${tempDir.path}/gruve_download_${DateTime.now().millisecondsSinceEpoch}$extension',
    );

    try {
      AppLogger.d('[MediaDownloadService] Downloading $url...');
      // A bare Dio instance is used deliberately: AppDio's shared singleton
      // runs auth/cache/dedup/retry interceptors built for the JSON API and
      // not safe for a raw binary media download (see post_service.dart's
      // draft re-upload download for the same pattern).
      await _downloadDio.download(
        url,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );

      AppLogger.d('[MediaDownloadService] Saving to gallery...');
      if (isVideo) {
        await Gal.putVideo(tempFile.path, album: 'Gruve');
      } else {
        await Gal.putImage(tempFile.path, album: 'Gruve');
      }
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    AppLogger.d(
      '[MediaDownloadService] Saved ${isVideo ? 'video' : 'image'} to gallery: $url',
    );
  }

  static String _extensionFromUrl(String url, {required bool isVideo}) {
    final fallback = isVideo ? '.mp4' : '.jpg';
    final path = Uri.tryParse(url)?.path ?? url;
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return fallback;
    }
    final ext = path.substring(dotIndex).toLowerCase();
    if (ext.length > 5) {
      // Not a plausible extension (e.g. a dot inside a query-less path segment).
      return fallback;
    }
    return ext;
  }
}
