import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/shared/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart';
import 'package:gruve_app/features/search/domain/entities/explore_reel_model.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';

/// Explore grid thumbnails come from [GET explore/reels/].
/// Full playback media is hydrated via [posts/get-post/?post_id=] when missing.
class ExploreReelsService {
  ExploreReelsService({Dio? dio, PostService? postService})
    : _dio = dio ?? AppDio.getInstance(),
      _postService = postService ?? PostService();

  final Dio _dio;
  final PostService _postService;

  static const Duration _resolveTimeout = Duration(seconds: 8);

  final Map<String, Post> _postCache = {};
  final Map<String, Future<Post?>> _resolveInFlight = {};

  VoidCallback? onPostsHydrated;

  Post? getCachedPost(String reelId) => _postCache[reelId];

  /// Best post for grid display — uses hydrated cache when available.
  Post displayPostFor(ExploreReel reel) {
    return _postCache[reel.id] ?? reel.toPreviewPost();
  }

  /// Post for the Instagram-style viewer — always carries explore user metadata.
  Post viewerPostFor(ExploreReel reel) {
    return displayPostFor(reel).mergedWith(
      other: reel.toPreviewPost(),
      displayName: reel.user.username,
      fallbackProfilePicture: reel.user.profilePicture,
    );
  }

  /// Hydrates caption, counts, and author avatar for the full-screen viewer.
  Future<Post?> resolveReelForViewer(ExploreReel reel) async {
    final baseline = viewerPostFor(reel);

    final cached = _postCache[reel.id];
    if (cached != null &&
        cached.profilePicture.trim().isNotEmpty &&
        _hasPlayableVideo(cached)) {
      return cached.mergedWith(
        other: baseline,
        displayName: reel.user.username,
        fallbackProfilePicture: reel.user.profilePicture,
      );
    }

    final inFlight = _resolveInFlight['viewer:${reel.id}'];
    if (inFlight != null) return inFlight;

    final future = _resolveReelPostInternal(
      reel,
      baseline,
      enrichProfile: true,
    );
    _resolveInFlight['viewer:${reel.id}'] = future;
    try {
      final resolved = await future;
      if (resolved != null) {
        _cacheIfBetter(reel.id, resolved);
        _notifyHydrated();
      }
      return resolved;
    } finally {
      _resolveInFlight.remove('viewer:${reel.id}');
    }
  }

  void prefetchReels(List<ExploreReel> reels, {int? maxItems}) {
    final slice = maxItems == null ? reels : reels.take(maxItems);
    final batch = <ExploreReel>[];

    for (final reel in slice) {
      batch.add(reel);
      if (reel.hasPlayableMedia) {
        _cacheIfBetter(reel.id, reel.toPreviewPost());
      }
    }

    if (batch.isEmpty) return;
    unawaited(_prefetchReelsBatch(batch));
  }

  Future<void> _prefetchReelsBatch(List<ExploreReel> reels) async {
    try {
      final unresolved = reels
          .where((reel) => !reel.hasPlayableMedia && reel.id.isNotEmpty)
          .toList();
      if (unresolved.isNotEmpty) {
        await Future.wait(unresolved.map(resolveReelPost), eagerError: false);
      }

      final posts = reels.map((reel) => displayPostFor(reel)).toList();
      await PostGridThumbnail.warmupPostsAwait(posts, max: posts.length);
      _notifyHydrated();
    } catch (e) {
      AppLogger.d('⚠️ [ExploreReelsService] batch prefetch failed: $e');
    }
  }

  Future<ExploreReelsPage> fetchReels({
    int page = 1,
    int limit = 10,
    String sort = 'trending',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final safeLimit = limit.clamp(1, 50);
    final safeSort = sort == 'latest' ? 'latest' : 'trending';

    final response = await _dio.get(
      ApiConstants.exploreReels,
      queryParameters: {'page': page, 'limit': safeLimit, 'sort': safeSort},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = _unwrapData(response.data);
    return ExploreReelsPage.fromJson(data);
  }

  Future<Post?> resolveReelPost(ExploreReel reel) async {
    final cached = _postCache[reel.id];
    if (cached != null && _hasPlayableVideo(cached)) {
      return cached;
    }

    if (reel.hasPlayableMedia) {
      final preview = reel.toPreviewPost();
      _cacheIfBetter(reel.id, preview);
      return preview;
    }

    final inFlight = _resolveInFlight[reel.id];
    if (inFlight != null) return inFlight;

    final future = _resolveReelPostInternal(reel, reel.toPreviewPost());
    _resolveInFlight[reel.id] = future;
    try {
      final resolved = await future;
      if (resolved != null) {
        _cacheIfBetter(reel.id, resolved);
        _notifyHydrated();
      }
      return resolved;
    } finally {
      _resolveInFlight.remove(reel.id);
    }
  }

  Future<Post?> _resolveReelPostInternal(
    ExploreReel reel,
    Post preview, {
    bool enrichProfile = false,
  }) async {
    try {
      final post = await _postService
          .fetchPostById(
            reel.id,
            authorUserId: reel.user.id,
            allowProfileFallback: true,
          )
          .timeout(_resolveTimeout);
      var merged = post.mergedWith(
        other: preview,
        displayName: reel.user.username,
        fallbackProfilePicture: reel.user.profilePicture,
      );

      if (enrichProfile &&
          merged.profilePicture.trim().isEmpty &&
          reel.user.id.isNotEmpty) {
        final avatar = await _fetchUserAvatar(reel.user.id);
        if (avatar != null && avatar.isNotEmpty) {
          merged = merged.mergedWith(
            other: Post(
              id: '',
              caption: '',
              media: '',
              userId: reel.user.id,
              likesCount: 0,
              commentsCount: 0,
              sharesCount: 0,
              isLiked: false,
              username: reel.user.username,
              isSubscribed: false,
              profilePicture: avatar,
            ),
          );
        }
      }

      if (_hasPlayableVideo(merged) || merged.gridPreviewUrl.isNotEmpty) {
        return merged;
      }
      return null;
    } catch (e) {
      AppLogger.d('⚠️ [ExploreReelsService] resolve ${reel.id} failed: $e');
      return null;
    }
  }

  Future<String?> _fetchUserAvatar(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;

    try {
      final token = await TokenStorage.getAccessToken();
      final response = await _dio.get(
        ApiConstants.userProfile(id),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final root = response.data;
      if (root is! Map) return null;

      final data = root['data'] ?? root;
      if (data is! Map) return null;

      final user = data['user'];
      if (user is! Map) return null;

      final userMap = Map<String, dynamic>.from(user);
      for (final key in const [
        'profile_picture',
        'profilePicture',
        'profile_image',
        'profileImage',
        'avatar',
        'avatar_url',
        'photo',
        'image',
      ]) {
        final value = userMap[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return Post.normalizeMediaUrl(value);
        }
      }
    } catch (e) {
      AppLogger.d('⚠️ [ExploreReelsService] avatar lookup $userId failed: $e');
    }
    return null;
  }

  void _cacheIfBetter(String reelId, Post candidate) {
    final existing = _postCache[reelId];
    if (existing == null) {
      _postCache[reelId] = candidate;
      return;
    }

    final existingScore = _postQualityScore(existing);
    final candidateScore = _postQualityScore(candidate);
    if (candidateScore >= existingScore) {
      _postCache[reelId] = existing.mergedWith(other: candidate);
    }
  }

  int _postQualityScore(Post post) {
    var score = 0;
    if (post.gridPreviewUrl.isNotEmpty) score += 2;
    if (post.profilePicture.isNotEmpty) score += 3;
    if (_hasPlayableVideo(post)) score += 4;
    if (post.caption.isNotEmpty) score += 1;
    return score;
  }

  void _notifyHydrated() => onPostsHydrated?.call();

  bool _hasPlayableVideo(Post post) {
    final media = post.media.trim();
    return post.isVideo &&
        media.isNotEmpty &&
        (media.startsWith('http://') || media.startsWith('https://'));
  }

  Map<String, dynamic> _unwrapData(dynamic root) {
    if (root is! Map) return {};

    final map = Map<String, dynamic>.from(root);
    final data = map['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return map;
  }
}
