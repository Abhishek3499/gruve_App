import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/story_view_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:get/get.dart';

/// Utility class for story-related operations
class StoryUtils {
  /// Navigate to story view screen if user has a story
  /// [isOwnProfile] - true when viewing own stories, false when viewing other user's stories
  static Future<void> navigateToStoryView(
    BuildContext context, {
    String? userId,
    required String displayName,
    required String username,
    required String avatar,
    bool isOwnProfile = false,
  }) async {
    if (kDebugMode) {
      debugPrint("\n🧭 ===== NAVIGATE TO STORY VIEW CALLED =====");
      debugPrint("🧭 userId: ${userId ?? 'me'} | displayName: $displayName");
    }

    // Show loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      StoryStateController.ensureRegistered();
      final storyStateController = Get.find<StoryStateController>();
      final storyController = StoryController();

      // Check cache first for instant response
      await storyStateController.loadStoriesFromStorage(userId);

      if (!context.mounted) return;

      // If we have cached stories, navigate immediately and refresh in background
      if (storyStateController.hasUserStory &&
          !storyStateController.isLoadingFromStorage) {
        Navigator.pop(context); // Close loading dialog

        final mediaPaths = storyStateController.currentUserStoryMediaPaths;
        final timestamps = storyStateController.storyTimestamps;
        final storyIds = storyStateController.currentUserStoryIds;

        _navigateToStoryScreen(
          context,
          userId: userId,
          mediaPaths: mediaPaths,
          displayName: displayName,
          username: username,
          avatar: avatar,
          timestamps: timestamps,
          storyIds: storyIds,
          isOwnProfile: isOwnProfile,
        );

        // Refresh stories in background
        _refreshStoriesInBackground(
          storyController,
          storyStateController,
          userId,
          username,
          avatar,
        );
      } else {
        // No cache, fetch from API
        await storyController.fetchStories(userId: userId);

        if (!context.mounted) return;

        if (storyController.isSuccess && storyController.stories.isNotEmpty) {
          Navigator.pop(context); // Close loading dialog

          final mediaPaths =
              storyController.stories.map((story) => story.mediaUrl).toList();
          final timestamps =
              storyController.stories.map((story) => story.createdAt).toList();

          await storyStateController.setStoriesFromStoryItems(
            storyController.stories,
            username: username,
            avatarUrl: avatar,
            userId: userId,
          );

          if (!context.mounted) return;

          _navigateToStoryScreen(
            context,
            userId: userId,
            mediaPaths: mediaPaths,
            displayName: displayName,
            username: username,
            avatar: avatar,
            timestamps: timestamps,
            storyItems: storyController.stories,
            isOwnProfile: isOwnProfile,
          );
        } else {
          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
          }
          if (kDebugMode) {
            debugPrint("⚠️ No stories found");
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      if (kDebugMode) {
        debugPrint("❌ Error navigating to story: $e");
      }
    }

    if (kDebugMode) {
      debugPrint("🏁 ===== NAVIGATE TO STORY VIEW END =====\n");
    }
  }

  static void _navigateToStoryScreen(
    BuildContext context, {
    String? userId,
    required List<String> mediaPaths,
    required String displayName,
    required String username,
    required String avatar,
    required List<DateTime> timestamps,
    List<String?>? storyIds,
    List<StoryItem>? storyItems,
    bool isOwnProfile = false,
  }) {
    if (kDebugMode) {
      debugPrint("🧭 [StoryUtils] _navigateToStoryScreen called");
      debugPrint("🧭 [StoryUtils] userId: ${userId ?? 'me'} | isOwnProfile: $isOwnProfile");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(
          userId: userId,
          mediaPaths: mediaPaths,
          displayName: displayName,
          username: username,
          avatarUrl: avatar,
          timestamps: timestamps,
          storyIds: storyIds,
          storyItems: storyItems,
          isOwnProfile: isOwnProfile,
        ),
      ),
    );
  }

  static Future<void> _refreshStoriesInBackground(
    StoryController storyController,
    StoryStateController storyStateController,
    String? userId,
    String username,
    String avatar,
  ) async {
    try {
      await storyController.fetchStories(userId: userId);

      if (storyController.isSuccess && storyController.stories.isNotEmpty) {
        await storyStateController.setStoriesFromStoryItems(
          storyController.stories,
          username: username,
          avatarUrl: avatar,
          userId: userId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("⚠️ Background refresh failed: $e");
      }
    }
  }

  /// Check if file is a video based on extension
  static bool isVideoFile(String filePath) {
    debugPrint("\n🎬 ===== CHECK VIDEO FILE CALLED =====");
    debugPrint("📁 File Path: $filePath");
    
    final extension = filePath.toLowerCase();
    bool isVideo = extension.endsWith('.mp4') ||
                   extension.endsWith('.mov') ||
                   extension.endsWith('.avi');
    
    debugPrint("🔍 Extension: $extension");
    debugPrint("🎬 Is Video: $isVideo");
    debugPrint("🏁 ===== CHECK VIDEO FILE END =====\n");
    
    return isVideo;
  }

  /// Get story time display text
  static String getStoryTimeDisplay(DateTime? createdAt) {
    debugPrint("\n⏰ ===== GET STORY TIME DISPLAY CALLED =====");
    debugPrint("📅 Created At: $createdAt");
    
    if (createdAt == null) {
      debugPrint("⚠️ No created time provided, returning 'Now'");
      debugPrint("🏁 ===== GET STORY TIME DISPLAY END =====\n");
      return 'Now';
    }
    
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    debugPrint("🕐 Time Difference: ${difference.inMinutes} minutes");
    
    String timeText;
    if (difference.inMinutes < 1) {
      timeText = 'Just now';
    } else if (difference.inHours < 1) {
      timeText = '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      timeText = '${difference.inHours}h ago';
    } else {
      timeText = '${difference.inDays}d ago';
    }
    
    debugPrint("🕐 Time Display: $timeText");
    debugPrint("🏁 ===== GET STORY TIME DISPLAY END =====\n");
    
    return timeText;
  }
}
