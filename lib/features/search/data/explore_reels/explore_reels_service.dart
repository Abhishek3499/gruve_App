import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/features/search/models/explore_reel_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';

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
      final posts = reels.map((reel) => displayPostFor(reel)).toList();
      await PostGridThumbnail.warmupPostsAwait(posts, max: posts.length);
      _notifyHydrated();
    } catch (e) {
      AppLogger.d('⚠️ [ExploreReelsService] batch prefetch failed: $e');
    }
  }

  Future<ExploreReelsPage> fetchReels({
    int page = 1,
    int limit = 20,
    String sort = 'trending',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final safeLimit = limit.clamp(1, 50);
    final safeSort = sort == 'latest' ? 'latest' : 'trending';

    final response = await _dio.get(
      'explore/reels/',
      queryParameters: {
        'page': page,
        'limit': safeLimit,
        'sort': safeSort,
      },
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

  Future<Post?> _resolveReelPostInternal(ExploreReel reel, Post preview) async {
    try {
      final post = await _postService
          .fetchPostById(
            reel.id,
            authorUserId: reel.user.id,
            allowProfileFallback: true,
          )
          .timeout(_resolveTimeout);
      final merged = post.mergedWith(other: preview);
      if (_hasPlayableVideo(merged) || merged.gridPreviewUrl.isNotEmpty) {
        return merged;
      }
      return null;
    } catch (e) {
      AppLogger.d('⚠️ [ExploreReelsService] resolve ${reel.id} failed: $e');
      return null;
    }
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
