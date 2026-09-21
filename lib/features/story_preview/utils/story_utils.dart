import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/story_view_screen.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_state_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_controller_notifier.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d("\n🧭 ===== NAVIGATE TO STORY VIEW CALLED =====");
    AppLogger.d("🧭 userId: ${userId ?? 'me'} | displayName: $displayName");

    // Show loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) => const _StoryOpeningLoader(),
    );

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final storyStateNotifier = container.read(
        storyStateNotifierProvider.notifier,
      );
      final storyController = container.read(storyControllerProvider.notifier);

      // Check cache first for instant response
      await storyStateNotifier.loadStoriesFromStorage(userId);

      if (!context.mounted) return;

      final storyState = container.read(storyStateNotifierProvider);
      final cachedStoryIds = storyState.currentUserStoryIds;
      final cachedStoriesHaveIds = cachedStoryIds.any(
        (id) => id?.trim().isNotEmpty ?? false,
      );
      final canUseCachedStories =
          storyState.hasUserStory &&
          !storyState.isLoadingFromStorage &&
          (!isOwnProfile || cachedStoriesHaveIds);

      // If cached own stories are missing API ids, fetch first so highlights work.
      if (canUseCachedStories) {
        Navigator.pop(context); // Close loading dialog

        final mediaPaths = storyState.currentUserStoryMediaPaths;
        final timestamps = storyState.storyTimestamps;
        final storyIds = storyState.currentUserStoryIds;

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
          storyStateNotifier,
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

          final mediaPaths = storyController.stories
              .map((story) => story.mediaUrl)
              .toList();
          final timestamps = storyController.stories
              .map((story) => story.createdAt)
              .toList();

          await storyStateNotifier.setStoriesFromStoryItems(
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
          AppLogger.d("⚠️ No stories found");
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      AppLogger.d("❌ Error navigating to story: $e");
    }

    AppLogger.d("🏁 ===== NAVIGATE TO STORY VIEW END =====\n");
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
    AppLogger.d("🧭 [StoryUtils] _navigateToStoryScreen called");
    AppLogger.d(
      "🧭 [StoryUtils] userId: ${userId ?? 'me'} | isOwnProfile: $isOwnProfile",
    );

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
    StoryControllerNotifier storyController,
    StoryStateNotifier storyStateNotifier,
    String? userId,
    String username,
    String avatar,
  ) async {
    try {
      await storyController.fetchStories(userId: userId);

      if (storyController.isSuccess && storyController.stories.isNotEmpty) {
        await storyStateNotifier.setStoriesFromStoryItems(
          storyController.stories,
          username: username,
          avatarUrl: avatar,
          userId: userId,
        );
      }
    } catch (e) {
      AppLogger.d("⚠️ Background refresh failed: $e");
    }
  }

  /// Check if file is a video based on extension
  static bool isVideoFile(String filePath) {
    AppLogger.d("\n🎬 ===== CHECK VIDEO FILE CALLED =====");
    AppLogger.d("📁 File Path: $filePath");

    final extension = filePath.toLowerCase();
    bool isVideo =
        extension.endsWith('.mp4') ||
        extension.endsWith('.mov') ||
        extension.endsWith('.avi');

    AppLogger.d("🔍 Extension: $extension");
    AppLogger.d("🎬 Is Video: $isVideo");
    AppLogger.d("🏁 ===== CHECK VIDEO FILE END =====\n");

    return isVideo;
  }

  /// Get story time display text
  static String getStoryTimeDisplay(DateTime? createdAt) {
    AppLogger.d("\n⏰ ===== GET STORY TIME DISPLAY CALLED =====");
    AppLogger.d("📅 Created At: $createdAt");

    if (createdAt == null) {
      AppLogger.d("⚠️ No created time provided, returning 'Now'");
      AppLogger.d("🏁 ===== GET STORY TIME DISPLAY END =====\n");
      return 'Now';
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    AppLogger.d("🕐 Time Difference: ${difference.inMinutes} minutes");

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

    AppLogger.d("🕐 Time Display: $timeText");
    AppLogger.d("🏁 ===== GET STORY TIME DISPLAY END =====\n");

    return timeText;
  }
}

class _StoryOpeningLoader extends StatelessWidget {
  const _StoryOpeningLoader();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF212235).withValues(alpha: 0.88),
            boxShadow: [
              BoxShadow(
                color: AppColors.loaderPrimary.withValues(alpha: 0.28),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(15),
            child: CircularProgressIndicator(
              color: AppColors.loaderDark,
              strokeWidth: 2.6,
            ),
          ),
        ),
      ),
    );
  }
}
