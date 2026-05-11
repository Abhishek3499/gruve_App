import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/cache/cache_interceptor.dart';

/// Service for automatic cache invalidation based on user actions
class CacheInvalidationService {
  static final CacheInvalidationService _instance = CacheInvalidationService._internal();
  factory CacheInvalidationService() => _instance;
  CacheInvalidationService._internal();

  final CacheInvalidationHelper _helper = CacheInvalidationHelper();

  /// Invalidate cache when user creates a post
  Future<void> onPostCreated(String postId) async {
    debugPrint('📝 [CacheInvalidation] Post created: $postId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.post, resourceId: postId),
    );
  }

  /// Invalidate cache when user likes/unlikes a post
  Future<void> onPostLiked(String postId) async {
    debugPrint('❤️ [CacheInvalidation] Post liked: $postId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.like, resourceId: postId),
    );
  }

  /// Invalidate cache when user follows/unfollows someone
  Future<void> onUserFollowed(String userId) async {
    debugPrint('👥 [CacheInvalidation] User followed: $userId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.follow, resourceId: userId),
    );
  }

  /// Invalidate cache when user comments on a post
  Future<void> onCommentAdded(String postId) async {
    debugPrint('💬 [CacheInvalidation] Comment added: $postId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.comment, resourceId: postId),
    );
  }

  /// Invalidate cache when user sends a message
  Future<void> onMessageSent(String conversationId) async {
    debugPrint('📤 [CacheInvalidation] Message sent: $conversationId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.message, resourceId: conversationId),
    );
  }

  /// Invalidate cache when user updates profile
  Future<void> onProfileUpdated(String userId) async {
    debugPrint('👤 [CacheInvalidation] Profile updated: $userId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.profileUpdate, resourceId: userId),
    );
  }

  /// Invalidate cache when user creates a story
  Future<void> onStoryCreated(String userId) async {
    debugPrint('📖 [CacheInvalidation] Story created: $userId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.storyCreate, resourceId: userId),
    );
  }

  /// Invalidate cache when user updates highlights
  Future<void> onHighlightUpdated(String highlightId) async {
    debugPrint('⭐ [CacheInvalidation] Highlight updated: $highlightId');
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.highlightUpdate, resourceId: highlightId),
    );
  }

  /// Invalidate all caches (useful for logout)
  Future<void> invalidateAll() async {
    debugPrint('🧹 [CacheInvalidation] Invalidating all caches');
    // This will be handled by CacheManager().clear() in AppDio
  }
}

/// Extension for easy cache invalidation in services
extension CacheInvalidation on CacheInvalidationService {
  /// Quick method to invalidate multiple related caches
  Future<void> invalidateMultiple(List<CacheAction> actions) async {
    for (final action in actions) {
      await _helper.invalidateOnAction(action);
    }
  }
}
