import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/feed/data/models/post_model.dart';
import 'package:gruve_app/core/network/api_client.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';

/// Repository for feed data operations
/// Handles API calls, caching, and data transformation
class FeedRepository {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  final CacheInvalidationService _cacheInvalidation;

  FeedRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient,
       _cacheManager = CacheManager(),
       _cacheInvalidation = CacheInvalidationService();

  /// Fetch feed posts with pagination
  Future<FeedResponse> fetchFeed({
    int page = 1,
    int limit = 20,
    String? userId,
    FeedType type = FeedType.all,
  }) async {
    try {
      final cacheKey = 'feed_${type.name}_${userId ?? 'me'}_${page}_$limit';
      final config = CacheConfigs.feed;

      // Try cache first
      final cached = await _cacheManager.getWithStaleRevalidate<Map<String, dynamic>>(
        cacheKey,
        (data) => data,
        config,
        () => _fetchFeedFromAPI(page, limit, userId, type),
        toJson: (data) => data,
      );

      if (cached.hasData && cached.data != null) {
        final response = FeedResponse.fromJson(cached.data!);
        debugPrint('🎯 [FeedRepository] Cache hit: ${response.posts.length} posts');
        return response;
      }

      // Fetch from API
      final response = await _fetchFeedFromAPI(page, limit, userId, type);
      debugPrint('🌐 [FeedRepository] API fetch: ${response.posts.length} posts');
      return response;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error fetching feed: $e');
      rethrow;
    }
  }

  /// Fetch feed from API
  Future<FeedResponse> _fetchFeedFromAPI(
    int page,
    int limit,
    String? userId,
    FeedType type,
  ) async {
    final endpoint = userId == null ? '/feed' : '/users/$userId/feed';
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'type': type.name,
    };

    final response = await _apiClient.get(endpoint, queryParams: queryParams);
    return FeedResponse.fromJson(response.data);
  }

  /// Like/unlike a post
  Future<bool> toggleLike(String postId, bool isLiked) async {
    try {
      final endpoint = isLiked ? '/posts/$postId/unlike' : '/posts/$postId/like';
      await _apiClient.post(endpoint);
      
      // Invalidate relevant caches
      await _cacheInvalidation.onPostLiked(postId);
      
      debugPrint('✅ [FeedRepository] Post ${isLiked ? 'unliked' : 'liked'}: $postId');
      return true;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error toggling like: $e');
      return false;
    }
  }

  /// Save/unsave a post
  Future<bool> toggleSave(String postId, bool isSaved) async {
    try {
      final endpoint = isSaved ? '/posts/$postId/unsave' : '/posts/$postId/save';
      await _apiClient.post(endpoint);
      
      // Invalidate saved posts cache
      await _cacheManager.invalidatePattern('saved');
      
      debugPrint('✅ [FeedRepository] Post ${isSaved ? 'unsaved' : 'saved'}: $postId');
      return true;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error toggling save: $e');
      return false;
    }
  }

  /// Share a post
  Future<bool> sharePost(String postId) async {
    try {
      await _apiClient.post('/posts/$postId/share');
      
      // Invalidate feed cache to update share count
      await _cacheInvalidation.onPostCreated(postId);
      
      debugPrint('✅ [FeedRepository] Post shared: $postId');
      return true;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error sharing post: $e');
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _apiClient.delete('/posts/$postId');
      
      // Invalidate all relevant caches
      await _cacheInvalidation.onPostCreated(postId);
      
      debugPrint('✅ [FeedRepository] Post deleted: $postId');
      return true;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error deleting post: $e');
      return false;
    }
  }

  /// Report a post
  Future<bool> reportPost(String postId, String reason) async {
    try {
      await _apiClient.post('/posts/$postId/report', data: {
        'reason': reason,
      });
      
      debugPrint('✅ [FeedRepository] Post reported: $postId');
      return true;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error reporting post: $e');
      return false;
    }
  }

  /// Get post details
  Future<PostModel?> getPostDetails(String postId) async {
    try {
      final cacheKey = 'post_$postId';
      final config = CacheConfigs.feed;

      // Try cache first
      final cached = await _cacheManager.get<Map<String, dynamic>>(
        cacheKey,
        (data) => data,
        config,
      );

      if (cached != null) {
        final post = PostModel.fromJson(cached);
        debugPrint('🎯 [FeedRepository] Post cache hit: $postId');
        return post;
      }

      // Fetch from API
      final response = await _apiClient.get('/posts/$postId');
      final post = PostModel.fromJson(response.data);
      
      // Cache the post
      await _cacheManager.put(cacheKey, response.data, config, toJson: (data) => data);
      
      debugPrint('🌐 [FeedRepository] Post API fetch: $postId');
      return post;
    } catch (e) {
      debugPrint('❌ [FeedRepository] Error fetching post details: $e');
      return null;
    }
  }
}

/// Feed response wrapper
class FeedResponse {
  final List<PostModel> posts;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final int totalPages;

  const FeedResponse({
    required this.posts,
    required this.totalCount,
    required this.hasMore,
    required this.currentPage,
    required this.totalPages,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    final postsData = json['posts'] as List<dynamic>? ?? [];
    final posts = postsData.map((post) => PostModel.fromJson(post)).toList();

    return FeedResponse(
      posts: posts,
      totalCount: json['total_count'] ?? json['totalCount'] ?? posts.length,
      hasMore: json['has_more'] ?? json['hasMore'] ?? false,
      currentPage: json['current_page'] ?? json['currentPage'] ?? 1,
      totalPages: json['total_pages'] ?? json['totalPages'] ?? 1,
    );
  }
}

/// Feed types
enum FeedType {
  all,
  trending,
  following,
  popular,
}
