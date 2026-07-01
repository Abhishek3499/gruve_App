import 'dart:async';
import 'dart:collection';

import 'package:video_player/video_player.dart';

/// Keeps initialized video controllers alive for instant thumbnail reuse.
class VideoFrameCache {
  VideoFrameCache._();

  static const int _maxEntries = 24;

  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  static final Queue<String> _lru = Queue<String>();
  static final Map<String, Future<VideoPlayerController?>> _inFlight =
      <String, Future<VideoPlayerController?>>{};

  static VideoPlayerController? peekReady(String url) {
    final key = url.trim();
    if (key.isEmpty) return null;

    final entry = _cache[key];
    final controller = entry?.controller;
    if (controller != null && controller.value.isInitialized) {
      return controller;
    }
    return null;
  }

  static Future<VideoPlayerController?> acquire(String url) async {
    final key = url.trim();
    if (key.isEmpty) return null;

    final cached = _cache[key];
    if (cached != null) {
      cached.refs++;
      _touchLru(key);
      return cached.controller;
    }

    final pending = _inFlight[key];
    if (pending != null) {
      final controller = await pending;
      if (controller == null) return null;

      final entry = _cache[key];
      if (entry != null) {
        entry.refs++;
        _touchLru(key);
        return entry.controller;
      }
      return controller;
    }

    final future = _createController(key);
    _inFlight[key] = future;
    try {
      final controller = await future;
      if (controller == null) return null;

      _cache[key] = _CacheEntry(controller: controller, refs: 1);
      _touchLru(key);
      _evictIfNeeded();
      return controller;
    } finally {
      _inFlight.remove(key);
    }
  }

  static void release(String url) {
    final key = url.trim();
    final entry = _cache[key];
    if (entry == null) return;

    if (entry.refs > 0) {
      entry.refs--;
    }
  }

  static Future<void> warmup(String url) async {
    final controller = await acquire(url);
    if (controller != null) {
      release(url);
    }
  }

  static Future<VideoPlayerController?> _createController(String key) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(key),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      await controller.seekTo(Duration.zero);
      return controller;
    } catch (_) {
      await controller.dispose();
      return null;
    }
  }

  static void _touchLru(String key) {
    _lru.remove(key);
    _lru.addLast(key);
  }

  static void _evictIfNeeded() {
    while (_cache.length > _maxEntries && _lru.isNotEmpty) {
      final oldest = _lru.first;
      final entry = _cache[oldest];
      if (entry == null) {
        _lru.removeFirst();
        continue;
      }

      if (entry.refs > 0) {
        _lru.removeFirst();
        _lru.addLast(oldest);
        break;
      }

      entry.controller.dispose();
      _cache.remove(oldest);
      _lru.removeFirst();
    }
  }
}

class _CacheEntry {
  final VideoPlayerController controller;
  int refs;

  _CacheEntry({required this.controller, this.refs = 0});
}
