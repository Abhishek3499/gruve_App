import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// VideoPreloader — TikTok-style intelligent video preloading
///
/// STRATEGY:
///   - Keep current video playing
///   - Preload next video in background
///   - Dispose previous video to save memory
///   - Max 2-3 videos in memory at once
///
/// MEMORY MANAGEMENT:
///   - Videos are ~10-50MB each in memory
///   - 3 videos = ~150MB max
///   - Aggressive disposal prevents memory leaks
/// ─────────────────────────────────────────────────────────────────────────────
class VideoPreloader {
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _preloading = {};
  final Set<int> _failed = {};
  
  bool _disposed = false;
  int _currentGeneration = 0;

  /// Get controller for specific index
  VideoPlayerController? getController(int index) => _controllers[index];

  /// Check if video failed to load
  bool hasFailed(int index) => _failed.contains(index);

  /// Check if video is currently preloading
  bool isPreloading(int index) => _preloading.contains(index);

  /// Main preload logic - called when user swipes to new video
  Future<void> preloadAround({
    required int currentIndex,
    required List<String> urls,
    required Function() onUpdate,
  }) async {
    if (_disposed) return;
    
    final generation = ++_currentGeneration;
    
    // Define which videos to keep in memory
    final targetIndexes = <int>{};
    
    // Current video (must be loaded)
    if (currentIndex >= 0 && currentIndex < urls.length) {
      targetIndexes.add(currentIndex);
    }
    
    // Next video (preload for smooth swipe)
    if (currentIndex + 1 < urls.length) {
      targetIndexes.add(currentIndex + 1);
    }
    
    // Previous video (keep if user swipes back)
    // Commented out to save memory - only keep current + next
    // if (currentIndex - 1 >= 0) {
    //   targetIndexes.add(currentIndex - 1);
    // }

    // Dispose videos outside the target range
    await _disposeOutsideRange(targetIndexes, onUpdate);

    // Load target videos
    for (final index in targetIndexes) {
      if (_disposed || generation != _currentGeneration) return;
      
      if (!_controllers.containsKey(index) && !_preloading.contains(index)) {
        unawaited(_loadVideo(index, urls[index], generation, onUpdate));
      }
    }
  }

  /// Load a single video
  Future<void> _loadVideo(
    int index,
    String url,
    int generation,
    Function() onUpdate,
  ) async {
    if (_disposed || _controllers.containsKey(index)) return;

    _preloading.add(index);
    onUpdate();

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url.trim()),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await controller.initialize();

      if (_disposed || generation != _currentGeneration) {
        await controller.dispose();
        return;
      }

      controller.setLooping(true);
      controller.setVolume(1.0);

      _controllers[index] = controller;
      _failed.remove(index);
      
      if (kDebugMode) {
        debugPrint('✅ Preloaded video $index');
      }
    } catch (e) {
      _failed.add(index);
      if (kDebugMode) {
        debugPrint('❌ Failed to preload video $index: $e');
      }
    } finally {
      _preloading.remove(index);
      onUpdate();
    }
  }

  /// Dispose videos outside target range
  Future<void> _disposeOutsideRange(
    Set<int> targetIndexes,
    Function() onUpdate,
  ) async {
    final toDispose = _controllers.keys
        .where((index) => !targetIndexes.contains(index))
        .toList();

    for (final index in toDispose) {
      final controller = _controllers.remove(index);
      if (controller != null) {
        await controller.pause();
        await controller.dispose();
        if (kDebugMode) {
          debugPrint('🗑️ Disposed video $index');
        }
      }
    }

    if (toDispose.isNotEmpty) {
      onUpdate();
    }
  }

  /// Dispose all controllers
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    for (final controller in _controllers.values) {
      await controller.pause();
      await controller.dispose();
    }

    _controllers.clear();
    _preloading.clear();
    _failed.clear();

    if (kDebugMode) {
      debugPrint('🧹 VideoPreloader disposed');
    }
  }
}
