import 'package:flutter/foundation.dart';

/// Global controller for managing story playback state
/// Handles pause/resume logic across the entire app
class StoryPlaybackController extends ChangeNotifier {
  // Singleton pattern
  static final StoryPlaybackController _instance =
      StoryPlaybackController._internal();
  factory StoryPlaybackController() => _instance;
  StoryPlaybackController._internal();

  // State
  bool _isPaused = false;
  bool _isInitialized = false;

  // Getters
  bool get isPaused => _isPaused;
  bool get isInitialized => _isInitialized;

  /// Initialize the controller
  void initialize() {
    if (kDebugMode) {
      debugPrint("🎬 [StoryPlaybackController] Initialized");
    }
    _isInitialized = true;
    _isPaused = false;
  }

  /// Pause story playback
  void pauseStory({String? reason}) {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint(
          "⚠️ [StoryPlaybackController] Cannot pause - not initialized",
        );
      }
      return;
    }

    if (_isPaused) {
      if (kDebugMode) {
        debugPrint(
          "⚠️ [StoryPlaybackController] Already paused - ignoring duplicate call",
        );
      }
      return;
    }

    _isPaused = true;
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        "⏸️ [StoryPlaybackController] Story Paused${reason != null ? ' - $reason' : ''}",
      );
    }
  }

  /// Resume story playback
  void resumeStory({String? reason}) {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint(
          "⚠️ [StoryPlaybackController] Cannot resume - not initialized",
        );
      }
      return;
    }

    if (!_isPaused) {
      if (kDebugMode) {
        debugPrint(
          "⚠️ [StoryPlaybackController] Already playing - ignoring duplicate call",
        );
      }
      return;
    }

    _isPaused = false;
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        "▶️ [StoryPlaybackController] Story Resumed${reason != null ? ' - $reason' : ''}",
      );
    }
  }

  /// Reset controller state
  void reset() {
    if (kDebugMode) {
      debugPrint("🔄 [StoryPlaybackController] Resetting controller");
    }
    _isPaused = false;
    _isInitialized = false;
    notifyListeners();
  }

  /// Toggle pause state
  void togglePause({String? reason}) {
    if (_isPaused) {
      resumeStory(reason: reason ?? "Toggle");
    } else {
      pauseStory(reason: reason ?? "Toggle");
    }
  }
}
