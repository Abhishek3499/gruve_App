import 'dart:async';
import 'dart:collection';

import 'package:video_player/video_player.dart';

/// Keeps initialized video controllers alive for instant thumbnail reuse.
class VideoFrameCache {
  VideoFrameCache._();

  static const int _maxEntries = 6;
  static const int _maxConcurrentInit = 3;

  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  static final Queue<String> _lru = Queue<String>();
  static final Map<String, Future<VideoPlayerController?>> _inFlight =
      <String, Future<VideoPlayerController?>>{};
  static int _activeInits = 0;
  static final Queue<Completer<void>> _initWaitQueue = Queue<Completer<void>>();

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
      _protect(key);
      return cached.controller;
    }

    final pending = _inFlight[key];
    if (pending != null) {
      final controller = await pending;
      if (controller == null) return null;

      var entry = _cache[key];
      if (entry == null) {
        _cache[key] = _CacheEntry(controller: controller);
        _touchLru(key);
        entry = _cache[key];
      }
      entry!.refs++;
      _touchLru(key);
      _protect(key);
      return entry.controller;
    }

    final future = _createController(key);
    _inFlight[key] = future;
    try {
      final controller = await future;
      if (controller == null) return null;

      _cache[key] = _CacheEntry(controller: controller, refs: 1);
      _touchLru(key);
      _protect(key);
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

  static Future<void> disposeAll() async {
    for (final entry in _cache.values) {
      await entry.controller.dispose();
    }
    _cache.clear();
    _lru.clear();
    _inFlight.clear();
  }

  static Future<void> warmup(String url) async {
    final controller = await acquire(url);
    if (controller != null) {
      _protect(url.trim());
      release(url);
    }
  }

  /// Preload many video first-frames in parallel (grids + feed posters).
  static Future<void> warmupMany(
    Iterable<String> urls, {
    int concurrency = _maxConcurrentInit,
  }) async {
    final pending = <String>{};
    for (final raw in urls) {
      final key = raw.trim();
      if (key.isEmpty) continue;
      if (peekReady(key) != null) continue;
      pending.add(key);
    }
    if (pending.isEmpty) return;

    final list = pending.toList();
    final safeConcurrency = concurrency.clamp(1, _maxConcurrentInit);
    for (var i = 0; i < list.length; i += safeConcurrency) {
      final batch = list.skip(i).take(safeConcurrency);
      await Future.wait(batch.map(warmup));
    }
  }

  /// Pauses every cached controller so only one clip can output audio at a time.
  static Future<void> pauseAll({String? activeUrl, double activeVolume = 1.0}) async {
    final activeKey = activeUrl?.trim() ?? '';

    for (final entry in _cache.entries) {
      final controller = entry.value.controller;
      if (!controller.value.isInitialized) continue;

      try {
        if (activeKey.isNotEmpty && entry.key == activeKey) {
          await controller.setVolume(activeVolume);
        } else {
          if (controller.value.isPlaying) {
            await controller.pause();
          }
          await controller.setVolume(0);
        }
      } catch (_) {}
    }
  }

  static Future<VideoPlayerController?> _createController(String key) async {
    await _acquireInitSlot();
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(key),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      try {
        await controller.initialize().timeout(const Duration(seconds: 12));
        await controller.setVolume(0);
        await controller.pause();
        await controller.seekTo(Duration.zero);
        return controller;
      } catch (_) {
        await controller.dispose();
        return null;
      }
    } finally {
      _releaseInitSlot();
    }
  }

  static Future<void> _acquireInitSlot() async {
    if (_activeInits < _maxConcurrentInit) {
      _activeInits++;
      return;
    }

    final waiter = Completer<void>();
    _initWaitQueue.add(waiter);
    await waiter.future;
    _activeInits++;
  }

  static void _releaseInitSlot() {
    _activeInits--;
    if (_initWaitQueue.isEmpty) return;

    final next = _initWaitQueue.removeFirst();
    if (!next.isCompleted) {
      next.complete();
    }
  }

  static void _protect(String key) {
    final entry = _cache[key];
    if (entry == null) return;
    entry.protectedUntil = DateTime.now().add(const Duration(minutes: 3));
  }

  static void _touchLru(String key) {
    _lru.remove(key);
    _lru.addLast(key);
  }

  static void _evictIfNeeded() {
    var guard = 0;
    while (_cache.length > _maxEntries && _lru.isNotEmpty && guard < _cache.length + 4) {
      guard++;
      final oldest = _lru.first;
      final entry = _cache[oldest];
      if (entry == null) {
        _lru.removeFirst();
        continue;
      }

      final isProtected = entry.refs > 0 ||
          entry.protectedUntil.isAfter(DateTime.now());
      if (isProtected) {
        _lru.removeFirst();
        _lru.addLast(oldest);
        continue;
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
  DateTime protectedUntil;

  _CacheEntry({
    required this.controller,
    this.refs = 0,
    DateTime? protectedUntil,
  }) : protectedUntil =
            protectedUntil ?? DateTime.fromMillisecondsSinceEpoch(0);
}
