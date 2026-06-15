import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/story_preview/api/post/api/video_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class PostShareFlowBridge {
  /// Home registers: show the existing processing overlay (same as camera flow).
  static Function(bool isVideo)? onShareStartProcessing;

  /// Home registers: dismiss overlay + cleanup [VideoService] if upload fails.
  static Function(String? errorMessage)? onShareUploadError;
  
  /// Home registers: show success snackbar with appropriate message
  static Function(bool isVideo)? onShowSuccessSnackbar;

  /// Home registers: switch [IndexedStack] to the video feed tab (index 0) so
  /// share / processing never leaves the user on Profile or another tab.
  static VoidCallback? onRequestShowHomeFeed;

  /// Home registers: switch [IndexedStack] to the profile tab (index 4)
  /// without pushing a new standalone screen.
  static VoidCallback? onRequestShowProfileTab;

  static dynamic _videoControllerRef;
  static VideoService? _currentVideoService;

  static bool _needsRefresh = false;

  static void notifyShareStartProcessing(bool isVideo) {
    onRequestShowHomeFeed?.call();
    onShareStartProcessing?.call(isVideo);
  }

  static void notifyStorySharedNavigateToProfile() {
    onRequestShowProfileTab?.call();
  }

  static void setVideoController(dynamic controller) {
    _videoControllerRef = controller;
    AppLogger.d("🔔 Bridge: Video controller reference set");
    
  }

  static void setVideoService(VideoService service) {
    _currentVideoService = service;
    AppLogger.d("🔔 Bridge: Video service reference set");
    
  }

  static void markProcessingCompleted() {
    if (_currentVideoService != null) {
      AppLogger.d("🔔 Bridge: Marking processing as completed");
      
      _currentVideoService!.markCompleted();
    }
  }

  /// After [SharePostScreen] is popped, run on the next frame so [HomeScreen] is
  /// visible: open overlay → upload → refresh feed (same [VideoFeedController.initVideos]
  /// as initial load) → mark completed.
  static void scheduleShareUploadAfterReturningHome({
    String? caption,
    String? mediaPath,
    String? locationName,
    bool audienceEveryone = true,
    bool audienceCloseFriends = false,
    bool scheduleReel = false,
    bool uploadHighQuality = false,
    bool hideLikeCount = false,
    bool hideShareCount = false,
    List<String>? taggedUserIds,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runShareUploadChain(
        caption: caption,
        mediaPath: mediaPath,
        locationName: locationName,
        audienceEveryone: audienceEveryone,
        audienceCloseFriends: audienceCloseFriends,
        scheduleReel: scheduleReel,
        uploadHighQuality: uploadHighQuality,
        hideLikeCount: hideLikeCount,
        hideShareCount: hideShareCount,
        taggedUserIds: taggedUserIds,
      );
    });
  }

  static bool _isVideoPath(String path) {
    return path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.mov') ||
        path.toLowerCase().endsWith('.avi');
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

  static Future<void> _runShareUploadChain({
    String? caption,
    String? mediaPath,
    String? locationName,
    bool audienceEveryone = true,
    bool audienceCloseFriends = false,
    bool scheduleReel = false,
    bool uploadHighQuality = false,
    bool hideLikeCount = false,
    bool hideShareCount = false,
    List<String>? taggedUserIds,
  }) async {
    try {
      final isVideo = mediaPath != null && mediaPath.isNotEmpty ? _isVideoPath(mediaPath) : false;
      AppLogger.d("🚀 [Bridge] Upload start: ${isVideo ? '🎥 VIDEO' : '🖼️ IMAGE'}");
        AppLogger.d("📁 [Bridge] Path: $mediaPath");
      
      
      notifyShareStartProcessing(isVideo);
      await _waitForProcessingOverlayFrame();
      
      await PostService().createPost(
        caption: caption,
        mediaPath: mediaPath,
        locationName: locationName,
        audienceEveryone: audienceEveryone,
        audienceCloseFriends: audienceCloseFriends,
        scheduleReel: scheduleReel,
        uploadHighQuality: uploadHighQuality,
        hideLikeCount: hideLikeCount,
        hideShareCount: hideShareCount,
        taggedUserIds: taggedUserIds,
      );
      
      AppLogger.d("✅ [Bridge] ${isVideo ? 'Video' : 'Photo'} upload completed");
      
      
      await notifyPostCreated(isVideo: isVideo);
      
      AppLogger.d("🔔 [Bridge] Post created notification finished");
      
    } catch (e) {
      AppLogger.d("❌ [Bridge] POST ERROR: $e");
      
      String? errorMessage;
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData != null && resData is Map) {
          errorMessage = resData['message']?.toString() ?? resData['error']?.toString();
        } else if (resData != null && resData is String) {
          errorMessage = resData;
        } else if (e.response?.statusMessage != null) {
          errorMessage = "Server error: ${e.response?.statusCode} ${e.response?.statusMessage}";
        } else {
          errorMessage = e.message;
        }
      } else {
        errorMessage = e.toString();
      }
      onShareUploadError?.call(errorMessage);
    }
  }

  static Future<void> notifyPostCreated({required bool isVideo}) async {
    AppLogger.d("🔔 [Bridge] notifyPostCreated called (isVideo=$isVideo)");
    

    if (_videoControllerRef != null) {
      AppLogger.d("🔄 [Bridge] Refreshing feed to show new post...");
      
      final result = await _videoControllerRef!.initVideos(refresh: true);
      if (kDebugMode) {
        if (result == true) {
          AppLogger.d("✅ [Bridge] Feed refreshed - new post should be visible");
        } else if (result == false) {
          AppLogger.d("❌ [Bridge] Feed refresh failed");
        } else {
          AppLogger.d("🔔 [Bridge] Feed refresh superseded by newer load");
        }
      }
      if (result == true) {
        _needsRefresh = false;
        _videoControllerRef!.playVideo(0);
        _videoControllerRef!.onScrollToTop?.call();
      } else if (result == false) {
        _needsRefresh = true;
      }
    } else {
      AppLogger.d("❌ [Bridge] No controller available, setting refresh flag");
        AppLogger.d(
          "🔄 [Bridge] Will refresh when home tab is accessed",
        );
      
      _needsRefresh = true;
    }

    await ProfileCountRefreshBridge.notifyCountsChanged(reason: 'post_created');
    markProcessingCompleted();
    
    // Show success snackbar
    onShowSuccessSnackbar?.call(isVideo);
  }

  static bool checkAndClearRefreshNeeded() {
    bool needed = _needsRefresh;
    if (needed) {
      AppLogger.d("🔄 Bridge: Refresh needed, clearing flag");
      
      _needsRefresh = false;
    }
    return needed;
  }

  static void clearCallbacks() {
    onShareStartProcessing = null;
    onShareUploadError = null;
    onShowSuccessSnackbar = null;
    onRequestShowHomeFeed = null;
    onRequestShowProfileTab = null;
    _videoControllerRef = null;
    _currentVideoService = null;
    _needsRefresh = false;
    AppLogger.d("🔔 Bridge: All callbacks cleared");
    
  }
}
