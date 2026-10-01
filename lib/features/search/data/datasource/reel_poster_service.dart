import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Poster frames for Discover reels that have no image thumbnail.
///
/// Uses a one-shot frame grab (MediaMetadataRetriever / AVAssetImageGenerator)
/// instead of a live VideoPlayerController, so cards never hold a hardware
/// decoder — those are needed by the story and reel players.
class ReelPosterService {
  ReelPosterService._();
  static final ReelPosterService instance = ReelPosterService._();

  static const int _maxConcurrent = 3;
  static const int _maxCached = 80;

  final LinkedHashMap<String, Uint8List> _memory =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List?>> _inFlight = {};
  final Set<String> _failed = {};
  final Queue<Completer<void>> _waiters = Queue();
  int _active = 0;

  /// Most recent failure, for debug display.
  String? lastError;

  Uint8List? cached(String videoUrl) {
    final bytes = _memory.remove(videoUrl);
    if (bytes != null) _memory[videoUrl] = bytes; // LRU touch
    return bytes;
  }

  /// Runs [task] with at most [_maxConcurrent] running at once.
  Future<T> limit<T>(Future<T> Function() task) async {
    if (_active >= _maxConcurrent) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) _waiters.removeFirst().complete();
    }
  }

  Future<Uint8List?> poster(String videoUrl) {
    final hit = cached(videoUrl);
    if (hit != null) return Future.value(hit);
    if (_failed.contains(videoUrl)) return Future.value(null);

    return _inFlight[videoUrl] ??= limit(() async {
      try {
        final bytes = await VideoThumbnail.thumbnailData(
          video: videoUrl,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 480,
          quality: 70,
          timeMs: 300,
        );
        if (bytes == null || bytes.isEmpty) {
          lastError = 'frame grab returned no data';
          _failed.add(videoUrl);
          return null;
        }
        _memory[videoUrl] = bytes;
        while (_memory.length > _maxCached) {
          _memory.remove(_memory.keys.first);
        }
        return bytes;
      } catch (e) {
        AppLogger.d('[ReelPosterService] poster failed for $videoUrl: $e');
        lastError = e.toString();
        _failed.add(videoUrl);
        return null;
      }
    }).whenComplete(() => _inFlight.remove(videoUrl));
  }
}
