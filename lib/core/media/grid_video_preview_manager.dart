import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages auto-playing video previews in grid cards.
/// At most [maxActive] videos play simultaneously.
/// Cards register/unregister by their unique [id].
class GridVideoPreviewManager {
  GridVideoPreviewManager._();
  static final GridVideoPreviewManager instance = GridVideoPreviewManager._();

  static const int maxActive = 2;

  // id → controller
  final Map<String, VideoPlayerController> _controllers = {};
  // ids currently playing
  final Set<String> _active = {};
  // visibility fraction per id
  final Map<String, double> _visibility = {};

  /// Notifies listeners with the set of currently active ids.
  final activeIds = ValueNotifier<Set<String>>({});

  /// Called by a card when its visibility changes.
  void onVisibilityChanged(String id, String videoUrl, double fraction) {
    _visibility[id] = fraction;

    if (fraction >= 0.5) {
      _maybeActivate(id, videoUrl);
    } else {
      _deactivate(id);
    }
  }

  /// Called when a card is disposed.
  void onDispose(String id) {
    _deactivate(id);
    _visibility.remove(id);
    final ctrl = _controllers.remove(id);
    ctrl?.dispose();
  }

  /// Pause all previews (e.g. when navigating away).
  void pauseAll() {
    for (final ctrl in _controllers.values) {
      if (ctrl.value.isPlaying) ctrl.pause();
    }
    _active.clear();
    activeIds.value = {};
  }

  VideoPlayerController? controllerFor(String id) => _controllers[id];

  Future<void> _maybeActivate(String id, String videoUrl) async {
    if (_active.contains(id)) return;
    if (_active.length >= maxActive) {
      // Deactivate the least visible active card.
      final leastVisible = _active.reduce(
        (a, b) => (_visibility[a] ?? 0) < (_visibility[b] ?? 0) ? a : b,
      );
      if ((_visibility[leastVisible] ?? 0) < (_visibility[id] ?? 0)) {
        _deactivate(leastVisible);
      } else {
        return;
      }
    }

    _active.add(id);
    activeIds.value = Set.from(_active);

    var ctrl = _controllers[id];
    if (ctrl == null) {
      ctrl = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controllers[id] = ctrl;
      try {
        await ctrl.initialize();
        await ctrl.setLooping(true);
        await ctrl.setVolume(0); // muted preview
      } catch (_) {
        _controllers.remove(id);
        _active.remove(id);
        activeIds.value = Set.from(_active);
        return;
      }
    }

    if (_active.contains(id)) {
      await ctrl.setVolume(0);
      await ctrl.play();
      activeIds.value = Set.from(_active);
    }
  }

  void _deactivate(String id) {
    if (!_active.contains(id)) return;
    _active.remove(id);
    _controllers[id]?.pause();
    activeIds.value = Set.from(_active);
  }
}
