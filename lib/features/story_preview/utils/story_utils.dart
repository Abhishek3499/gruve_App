import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/story_view_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';

/// Utility class for story-related operations
class StoryUtils {
  /// Navigate to story view screen if user has a story
  static void navigateToStoryView(BuildContext context) {
    debugPrint("\n🧭 ===== NAVIGATE TO STORY VIEW CALLED =====");
    
    final storyController = StoryStateController();
    debugPrint("📊 Has User Story: ${storyController.hasUserStory}");
    
    if (storyController.hasUserStory) {
      debugPrint("👤 Username: ${storyController.username ?? 'Not available'}");
      debugPrint("🖼️ Avatar: ${storyController.avatarUrl ?? 'Not available'}");
      debugPrint("📱 Media Paths: ${storyController.currentUserStoryMediaPaths.length} items");
      debugPrint("⏰ Timestamps: ${storyController.storyTimestamps.length} items");
      
      debugPrint("🚀 Navigating to StoryViewScreen...");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewScreen(
            mediaPaths: storyController.currentUserStoryMediaPaths,
            username: storyController.username,
            avatarUrl: storyController.avatarUrl,
            timestamps: storyController.storyTimestamps,
          ),
        ),
      );
      debugPrint("✅ Navigation successful");
    } else {
      debugPrint("⚠️ No user stories found, cannot navigate");
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
