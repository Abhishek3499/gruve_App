import 'dart:async';

import 'package:gruve_app/features/home/presentation/controllers/share_upload_error_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_upload_progress_state.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/story_preview/data/datasource/video_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';

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

  /// Reactive state for the floating upload progress bubble on the Reel/Home feed.
  static final ValueNotifier<PostUploadProgressState> uploadProgress =
      ValueNotifier<PostUploadProgressState>(const PostUploadProgressState());

  static Timer? _creepTimer;
  static Timer? _autoHideTimer;

  static dynamic _videoControllerRef;
  static VideoService? _currentVideoService;

  static bool _needsRefresh = false;

  /// Starts the floating upload progress state
  static void startUploadProgress({
    required bool isVideo,
    String? mediaPath,
  }) {
    _creepTimer?.cancel();
    _autoHideTimer?.cancel();
    uploadProgress.value = PostUploadProgressState(
      isVisible: true,
      progress: 6.0,
      isVideo: isVideo,
      mediaPath: mediaPath,
      isCompleted: false,
      isFailed: false,
    );
  }

  /// Updates upload progress (0.0 to 99.0)
  static void updateUploadProgress(double progress) {
    if (!uploadProgress.value.isVisible || uploadProgress.value.isCompleted) {
      return;
    }
    final clamped = progress.clamp(0.0, 99.0);
    if (clamped > uploadProgress.value.progress) {
      uploadProgress.value = uploadProgress.value.copyWith(progress: clamped);
    }
  }

  /// Creeps progress forward smoothly while awaiting backend processing/transcoding
  static void _startProcessingCreep({double startProgress = 85.0}) {
    _creepTimer?.cancel();
    double current = uploadProgress.value.progress;
    if (current < startProgress) {
      current = startProgress;
    }
    uploadProgress.value = uploadProgress.value.copyWith(progress: current);

    _creepTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!uploadProgress.value.isVisible ||
          uploadProgress.value.isCompleted ||
          uploadProgress.value.isFailed) {
        timer.cancel();
        return;
      }
      final double currentP = uploadProgress.value.progress;
      // Asymptotically approach 98%
      final double next = currentP + (98.0 - currentP) * 0.05;
      if (next >= 98.0) {
        uploadProgress.value = uploadProgress.value.copyWith(progress: 98.0);
        timer.cancel();
      } else {
        uploadProgress.value = uploadProgress.value.copyWith(progress: next);
      }
    });
  }

  /// Marks upload as completed with celebratory 100% state, then auto-hides
  static void completeUploadProgress() {
    _creepTimer?.cancel();
    _autoHideTimer?.cancel();
    uploadProgress.value = uploadProgress.value.copyWith(
      progress: 100.0,
      isCompleted: true,
      isFailed: false,
    );

    // Auto-hide the bubble smoothly after completion
    _autoHideTimer = Timer(const Duration(milliseconds: 1600), () {
      uploadProgress.value = const PostUploadProgressState(isVisible: false);
    });
  }

  /// Marks upload as failed, displays error state, then auto-hides
  static void failUploadProgress(String? errorMessage) {
    _creepTimer?.cancel();
    _autoHideTimer?.cancel();
    uploadProgress.value = uploadProgress.value.copyWith(
      isFailed: true,
      errorMessage: errorMessage,
    );

    _autoHideTimer = Timer(const Duration(milliseconds: 2400), () {
      uploadProgress.value = const PostUploadProgressState(isVisible: false);
    });
  }

  static void notifyShareStartProcessing(bool isVideo) {
    onRequestShowHomeFeed?.call();
    if (!uploadProgress.value.isVisible) {
      startUploadProgress(isVideo: isVideo);
      _startProcessingCreep(startProgress: 12.0);
    }
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
    completeUploadProgress();
    if (_currentVideoService != null) {
      AppLogger.d("🔔 Bridge: Marking processing as completed");
      _currentVideoService!.markCompleted();
    }
  }

  /// After [SharePostScreen] is popped, run on the next frame so [HomeScreen] is
  /// visible: open floating progress bubble → upload with byte tracking → refresh feed
  /// (same [VideoFeedController.initVideos] as initial load) → mark completed.
  static void scheduleShareUploadAfterReturningHome({
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
    String? locationName,
    List<String>? taggedUserIds,
    String? draftId,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runShareUploadChain(
        caption: caption,
        mediaPath: mediaPath,
        mediaMimeType: mediaMimeType,
        locationName: locationName,
        taggedUserIds: taggedUserIds,
        draftId: draftId,
      );
    });
  }

  static Future<void> _runShareUploadChain({
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
    String? locationName,
    List<String>? taggedUserIds,
    String? draftId,
  }) async {
    try {
      final isVideo = mediaPath != null && mediaPath.isNotEmpty
          ? await LocalMediaUtils.isVideoForUpload(
              mediaPath,
              mimeType: mediaMimeType,
            )
          : false;
      AppLogger.d(
        "🚀 [Bridge] Upload start: ${isVideo ? '🎥 VIDEO' : '🖼️ IMAGE'}",
      );
      AppLogger.d("📁 [Bridge] Path: $mediaPath");

      // Switch to home feed first
      onRequestShowHomeFeed?.call();

      // Launch the floating upload progress bubble
      startUploadProgress(isVideo: isVideo, mediaPath: mediaPath);
      onShareStartProcessing?.call(isVideo);

      final response = await PostService().createPost(
        caption: caption,
        mediaPath: mediaPath,
        locationName: locationName,
        taggedUserIds: taggedUserIds,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final double ratio = (sent / total).clamp(0.0, 1.0);
            // Map upload byte transfer to 8% -> 85%
            final double currentProgress = 8.0 + (ratio * 77.0);
            updateUploadProgress(currentProgress);
            if (sent >= total) {
              _startProcessingCreep(startProgress: 85.0);
            }
          }
        },
      );

      AppLogger.d("✅ [Bridge] ${isVideo ? 'Video' : 'Photo'} upload completed");

      if (draftId != null && draftId.isNotEmpty) {
        AppLogger.d(
          "🧹 [Bridge] Deleting draft after successful share: $draftId",
        );
        await PostService().deleteDraft(draftId);
      }

      completeUploadProgress();
      await notifyPostCreated(isVideo: isVideo, newPost: response.data);

      AppLogger.d("🔔 [Bridge] Post created notification finished");
    } catch (e) {
      AppLogger.d("❌ [Bridge] POST ERROR: $e");

      final errorMessage = parseShareUploadError(e);
      failUploadProgress(errorMessage);
      onShareUploadError?.call(errorMessage);
    }
  }

  static Future<void> notifyPostCreated({
    required bool isVideo,
    Post? newPost,
  }) async {
    AppLogger.d(
      "🔔 [Bridge] notifyPostCreated called (isVideo=$isVideo, newPost=${newPost != null})",
    );

    if (_videoControllerRef != null) {
      if (newPost != null) {
        AppLogger.d(
          "🔄 [Bridge] Instantly prepending new post ${newPost.id} to feed...",
        );
        _videoControllerRef!.prependPost(newPost);
        _videoControllerRef!.playVideo(0);
        _videoControllerRef!.onScrollToTop?.call();
        _needsRefresh = false;
      } else {
        AppLogger.d(
          "🔄 [Bridge] Refreshing feed to show new post (fallback)...",
        );
        final result = await _videoControllerRef!.initVideos(refresh: true);
        if (kDebugMode) {
          if (result == true) {
            AppLogger.d(
              "✅ [Bridge] Feed refreshed - new post should be visible",
            );
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
      }
    } else {
      AppLogger.d("❌ [Bridge] No controller available, setting refresh flag");
      AppLogger.d("🔄 [Bridge] Will refresh when home tab is accessed");

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
    _creepTimer?.cancel();
    _autoHideTimer?.cancel();
    onShareStartProcessing = null;
    onShareUploadError = null;
    onShowSuccessSnackbar = null;
    onRequestShowHomeFeed = null;
    onRequestShowProfileTab = null;
    _videoControllerRef = null;
    _currentVideoService = null;
    _needsRefresh = false;
    uploadProgress.value = const PostUploadProgressState(isVisible: false);
    AppLogger.d("🔔 Bridge: All callbacks cleared");
  }
}
