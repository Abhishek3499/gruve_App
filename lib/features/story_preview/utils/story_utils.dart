import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/story_view_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';

/// Utility class for story-related operations
class StoryUtils {
  /// Navigate to story view screen if user has a story
  static Future<void> navigateToStoryView(
    BuildContext context, {
    String? userId,
    required String displayName,
    required String username,
    required String avatar,
  }) async {
    debugPrint("\n🧭 ===== NAVIGATE TO STORY VIEW CALLED =====");

    print("🧭 NAVIGATION DATA:");
    print("➡️ userId: ${userId ?? 'me (own profile)'}");
    print("➡️ displayName: $displayName");
    print("➡️ username: $username");
    print("➡️ avatar: $avatar");

    final storyStateController = StoryStateController();
    debugPrint("📊 Has User Story (local): ${storyStateController.hasUserStory}");

    // Fetch stories from API
    debugPrint("🌐 Fetching stories from API...");
    final storyController = StoryController();
    await storyController.fetchStories(userId: userId);

    if (storyController.isSuccess && storyController.stories.isNotEmpty) {
      debugPrint("✅ Stories fetched from API successfully");
      debugPrint(" Total stories: ${storyController.stories.length}");

      // Convert API stories to StoryMediaModel format
      final mediaPaths = storyController.stories.map((story) => story.mediaUrl).toList();
      final timestamps = storyController.stories.map((story) => story.createdAt).toList();

      debugPrint("📱 Media Paths: ${mediaPaths.length} items");
      debugPrint("⏰ Timestamps: ${timestamps.length} items");

      // Update local state controller with API data
      await storyStateController.setStoriesFromAPI(
        mediaPaths,
        createdAts: timestamps,
        username: username,
        avatarUrl: avatar,
      );

      debugPrint("🚀 Navigating to StoryViewScreen...");
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
          ),
        ),
      );
      debugPrint("✅ Navigation successful");
    } else {
      debugPrint("⚠️ No stories found from API or fetch failed");
      debugPrint("💬 Message: ${storyController.message}");
    }

    debugPrint("🏁 ===== NAVIGATE TO STORY VIEW END =====\n");
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
