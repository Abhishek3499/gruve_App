import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Service for automatic cache invalidation based on user actions
class CacheInvalidationService {
  static final CacheInvalidationService _instance =
      CacheInvalidationService._internal();
  factory CacheInvalidationService() => _instance;
  CacheInvalidationService._internal();

  final CacheInvalidationHelper _helper = CacheInvalidationHelper();

  /// Invalidate cache when user creates a post
  Future<void> onPostCreated(String postId) async {
    AppLogger.debug('CacheInvalidation', 'post_created', data: {'postId': postId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.post, resourceId: postId),
    );
  }

  /// Invalidate cache when user likes/unlikes a post
  Future<void> onPostLiked(String postId) async {
    AppLogger.debug('CacheInvalidation', 'post_liked', data: {'postId': postId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.like, resourceId: postId),
    );
  }

  /// Invalidate cache when user follows/unfollows someone
  Future<void> onUserFollowed(String userId) async {
    AppLogger.debug('CacheInvalidation', 'user_followed', data: {'userId': userId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.follow, resourceId: userId),
    );
  }

  /// Invalidate cache when user comments on a post
  Future<void> onCommentAdded(String postId) async {
    AppLogger.debug('CacheInvalidation', 'comment_added', data: {'postId': postId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.comment, resourceId: postId),
    );
  }

  /// Invalidate cache when user sends a message
  Future<void> onMessageSent(String conversationId) async {
    AppLogger.debug('CacheInvalidation', 'message_sent', data: {'conversationId': conversationId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.message, resourceId: conversationId),
    );
  }

  /// Invalidate cache when user updates profile
  Future<void> onProfileUpdated(String userId) async {
    AppLogger.debug('CacheInvalidation', 'profile_updated', data: {'userId': userId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.profileUpdate, resourceId: userId),
    );
  }

  /// Invalidate cache when user creates a story
  Future<void> onStoryCreated(String userId) async {
    AppLogger.debug('CacheInvalidation', 'story_created', data: {'userId': userId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.storyCreate, resourceId: userId),
    );
  }

  /// Invalidate cache when user watches a story — the feed's cached
  /// has_active_story/has_unseen_story/has_close_friends_story flags for
  /// this author are now stale and must be re-fetched, not served from disk.
  Future<void> onStoryViewed(String userId) async {
    AppLogger.debug('CacheInvalidation', 'story_viewed', data: {'userId': userId});
    await _helper.invalidateOnAction(
      CacheAction(type: CacheActionType.storyView, resourceId: userId),
    );
  }

  /// Invalidate cache when user updates highlights
  Future<void> onHighlightUpdated(String highlightId) async {
    AppLogger.debug('CacheInvalidation', 'highlight_updated', data: {'highlightId': highlightId});
    await _helper.invalidateOnAction(
      CacheAction(
        type: CacheActionType.highlightUpdate,
        resourceId: highlightId,
      ),
    );
  }

  /// Invalidate all caches (useful for logout)
  Future<void> invalidateAll() async {
    AppLogger.debug('CacheInvalidation', 'invalidate_all');
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

/// Cache invalidation helper
class CacheInvalidationHelper {
  final CacheManager _cacheManager = CacheManager();

  /// Invalidate cache entries based on action
  Future<void> invalidateOnAction(
    CacheAction action, {
    String? resourceId,
  }) async {
    switch (action.type) {
      case CacheActionType.post:
        await _invalidateOnPost(resourceId);
        break;
      case CacheActionType.like:
        await _invalidateOnLike(resourceId);
        break;
      case CacheActionType.follow:
        await _invalidateOnFollow(resourceId);
        break;
      case CacheActionType.comment:
        await _invalidateOnComment(resourceId);
        break;
      case CacheActionType.message:
        await _invalidateOnMessage(resourceId);
        break;
      case CacheActionType.profileUpdate:
        await _invalidateOnProfileUpdate(resourceId);
        break;
      case CacheActionType.storyCreate:
        await _invalidateOnStoryCreate(resourceId);
        break;
      case CacheActionType.storyView:
        await _invalidateOnStoryView(resourceId);
        break;
      case CacheActionType.highlightUpdate:
        await _invalidateOnHighlightUpdate(resourceId);
        break;
      case CacheActionType.draft:
        await _invalidateOnDraft();
        break;
    }
  }

  Future<void> _invalidateOnPost(String? postId) async {
    // Invalidate feed cache
    await _cacheManager.invalidatePattern('feed');
    await _cacheManager.invalidatePattern('posts');

    // Invalidate user profile
    await _cacheManager.invalidatePattern('profile');

    // Invalidate drafts cache if post was created from draft
    await _cacheManager.invalidatePattern(ApiConstants.postDrafts);
    await _cacheManager.invalidatePattern('drafts');

    AppLogger.debug('CacheInvalidation', 'invalidated', data: {'reason': 'post', 'postId': postId});
  }

  Future<void> _invalidateOnLike(String? postId) async {
    // Invalidate feed and post details
    await _cacheManager.invalidatePattern('feed');
    await _cacheManager.invalidatePattern('posts/$postId');

    AppLogger.debug('CacheInvalidation', 'invalidated', data: {'reason': 'like', 'postId': postId});
  }

  Future<void> _invalidateOnFollow(String? userId) async {
    // Invalidate profile caches
    await _cacheManager.invalidatePattern('profile');
    await _cacheManager.invalidatePattern('user/profile');
    if (userId != null && userId.isNotEmpty) {
      await _cacheManager.invalidatePattern(userId);
    }
    await _cacheManager.invalidatePattern(ApiConstants.getPost);

    AppLogger.debug('CacheInvalidation', 'invalidated', data: {'reason': 'follow', 'userId': userId});
  }

  Future<void> _invalidateOnComment(String? postId) async {
    // Invalidate comment cache for specific post or all comments
    await _cacheManager.invalidatePattern('posts/comments');
    if (postId != null && postId.isNotEmpty) {
      await _cacheManager.invalidatePattern('post_id: $postId');
      await _cacheManager.invalidatePattern('post_id=$postId');
      await _cacheManager.invalidatePattern('posts/$postId');
    }
    // Invalidate post details and feed
    await _cacheManager.invalidatePattern('feed');

    AppLogger.debug('CacheInvalidation', 'invalidated', data: {'reason': 'comment', 'postId': postId});
  }

  Future<void> _invalidateOnMessage(String? conversationId) async {
    // Invalidate conversation caches
    await _cacheManager.invalidatePattern('conversations');
    if (conversationId != null) {
      await _cacheManager.invalidatePattern('conversations/$conversationId');
    }

    AppLogger.debug(
      'CacheInvalidation',
      'invalidated',
      data: {'reason': 'message', 'conversationId': conversationId},
    );
  }

  Future<void> _invalidateOnProfileUpdate(String? userId) async {
    // Invalidate all profile-related caches
    await _cacheManager.invalidatePattern('profile');
    await _cacheManager.invalidatePattern('user/$userId');

    AppLogger.debug(
      'CacheInvalidation',
      'invalidated',
      data: {'reason': 'profile_update', 'userId': userId},
    );
  }

  Future<void> _invalidateOnStoryCreate(String? userId) async {
    // Invalidate story caches
    await _cacheManager.invalidatePattern('stories');
    await _cacheManager.invalidatePattern('profile');

    AppLogger.debug(
      'CacheInvalidation',
      'invalidated',
      data: {'reason': 'story_create', 'userId': userId},
    );
  }

  Future<void> _invalidateOnStoryView(String? userId) async {
    // The feed and profile responses embed this author's
    // has_active_story/has_unseen_story/has_close_friends_story flags —
    // those are now stale the moment a view is recorded.
    await _cacheManager.invalidatePattern('feed');
    await _cacheManager.invalidatePattern('posts');
    await _cacheManager.invalidatePattern('profile');

    AppLogger.debug(
      'CacheInvalidation',
      'invalidated',
      data: {'reason': 'story_view', 'userId': userId},
    );
  }

  Future<void> _invalidateOnHighlightUpdate(String? highlightId) async {
    // Invalidate highlight caches
    await _cacheManager.invalidatePattern('highlights');
    if (highlightId != null) {
      await _cacheManager.invalidatePattern('highlights/$highlightId');
    }

    AppLogger.debug(
      'CacheInvalidation',
      'invalidated',
      data: {'reason': 'highlight_update', 'highlightId': highlightId},
    );
  }

  Future<void> _invalidateOnDraft() async {
    await _cacheManager.invalidatePattern(ApiConstants.postDrafts);
    await _cacheManager.invalidatePattern('drafts');
    AppLogger.debug('CacheInvalidation', 'invalidated', data: {'reason': 'drafts'});
  }
}

/// Cache action types for invalidation
enum CacheActionType {
  post,
  like,
  follow,
  comment,
  message,
  profileUpdate,
  storyCreate,
  storyView,
  highlightUpdate,
  draft,
}

/// Cache action for invalidation
class CacheAction {
  final CacheActionType type;
  final String? resourceId;

  CacheAction({required this.type, this.resourceId});
}
