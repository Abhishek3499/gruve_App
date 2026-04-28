import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/story_preview/api/post/api/video_service.dart';

class PostShareFlowBridge {
  /// Home registers: show the existing processing overlay (same as camera flow).
  static Function()? onShareStartProcessing;

  /// Home registers: dismiss overlay + cleanup [VideoService] if upload fails.
  static Function()? onShareUploadError;

  /// Home registers: switch [IndexedStack] to the video feed tab (index 0) so
  /// share / processing never leaves the user on Profile or another tab.
  static VoidCallback? onRequestShowHomeFeed;

  /// Home registers: switch [IndexedStack] to the profile tab (index 4)
  /// without pushing a new standalone screen.
  static VoidCallback? onRequestShowProfileTab;

  static dynamic _videoControllerRef;
  static VideoService? _currentVideoService;

  static bool _needsRefresh = false;

  static void notifyShareStartProcessing() {
    onRequestShowHomeFeed?.call();
    onShareStartProcessing?.call();
  }

  static void notifyStorySharedNavigateToProfile() {
    onRequestShowProfileTab?.call();
  }

  static void setVideoController(dynamic controller) {
    _videoControllerRef = controller;
    print("🔔 Bridge: Video controller reference set");
  }

  static void setVideoService(VideoService service) {
    _currentVideoService = service;
    print("🔔 Bridge: Video service reference set");
  }

  static void markProcessingCompleted() {
    if (_currentVideoService != null) {
      print("🔔 Bridge: Marking processing as completed");
      _currentVideoService!.markCompleted();
    }
  }

  /// After [SharePostScreen] is popped, run on the next frame so [HomeScreen] is
  /// visible: open overlay → upload → refresh feed (same [VideoFeedController.initVideos]
  /// as initial load) → mark completed.
  static void scheduleShareUploadAfterReturningHome({
    required String caption,
    required String mediaPath,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runShareUploadChain(caption, mediaPath);
    });
  }

  /// Ensures the processing overlay route is committed before [createPost] runs.
  /// Otherwise a fast failure could call [onShareUploadError] while the dialog
  /// is not on the stack yet, and a stray [Navigator.pop] would remove [HomeScreen].
  static Future<void> _waitForProcessingOverlayFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  static Future<void> _runShareUploadChain(
    String caption,
    String mediaPath,
  ) async {
    try {
      notifyShareStartProcessing();
      await _waitForProcessingOverlayFrame();
      await PostService().createPost(caption: caption, mediaPath: mediaPath);
      print("✅ API call completed successfully");
      await notifyPostCreated();
      print("🔔 Post created notification finished");
    } catch (e) {
      print("❌ POST ERROR: $e");
      onShareUploadError?.call();
    }
  }

  /// Refreshes via the same [VideoFeedController.initVideos] used on first home open.
  /// Logs success only after GET completes successfully. Calls [markProcessingCompleted]
  /// after refresh so the overlay can close after the feed is updated.
  static Future<void> notifyPostCreated() async {
    print("🔔 Bridge: notifyPostCreated called");

    if (_videoControllerRef != null) {
      print("🔔 Bridge: Refreshing video feed (awaiting GET)...");
      final result = await _videoControllerRef!.initVideos(refresh: true);
      if (result == true) {
        print("✅ Bridge: Video feed refreshed successfully");
        _needsRefresh = false;
      } else if (result == false) {
        print("❌ Bridge: Video feed refresh failed");
        _needsRefresh = true;
      } else {
        print("🔔 Bridge: Video feed refresh superseded by newer load");
      }
    } else {
      print("❌ Bridge: No refresh method available, setting flag");
      print(
        "🔄 Bridge: Refresh flag set, will refresh when home tab is accessed",
      );
      _needsRefresh = true;
    }

    await ProfileCountRefreshBridge.notifyCountsChanged(reason: 'post_created');
    markProcessingCompleted();
  }

  static bool checkAndClearRefreshNeeded() {
    bool needed = _needsRefresh;
    if (needed) {
      print("🔄 Bridge: Refresh needed, clearing flag");
      _needsRefresh = false;
    }
    return needed;
  }

  static void clearCallbacks() {
    onShareStartProcessing = null;
    onShareUploadError = null;
    onRequestShowHomeFeed = null;
    onRequestShowProfileTab = null;
    _videoControllerRef = null;
    _currentVideoService = null;
    _needsRefresh = false;
    print("🔔 Bridge: All callbacks cleared");
  }
}
