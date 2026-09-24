import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/shared/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/profile/data/repo/profile_repository.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';

import 'package:gruve_app/features/profile/domain/entities/profile_model.dart';
import 'package:gruve_app/features/profile/domain/entities/profile_stats_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

// Simple pagination state for each tab
class _TabPaginationState {
  int page = 1;
  int limit = 10;
  List<Post> posts = [];
  bool hasNext = true;
  bool isLoading = false;
  String? error;

  _TabPaginationState();

  _TabPaginationState copyWith({
    int? page,
    int? limit,
    List<Post>? posts,
    bool? hasNext,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    final newState = _TabPaginationState();
    newState.page = page ?? this.page;
    newState.limit = limit ?? this.limit;
    newState.posts = posts ?? this.posts;
    newState.hasNext = hasNext ?? this.hasNext;
    newState.isLoading = isLoading ?? this.isLoading;
    newState.error = clearError ? null : (error ?? this.error);
    return newState;
  }

  _TabPaginationState reset() {
    final newState = _TabPaginationState();
    newState.page = 1;
    newState.limit = limit;
    newState.posts = [];
    newState.hasNext = true;
    newState.isLoading = false;
    newState.error = null;
    return newState;
  }

  bool get canLoadMore => hasNext && !isLoading;
}

class ProfileController {
  final ProfileRepository _repository;
  final PostService _postService;

  // Pagination states for each tab
  final _TabPaginationState _allTabState = _TabPaginationState();
  final _TabPaginationState _trendingTabState = _TabPaginationState();
  final _TabPaginationState _likedTabState = _TabPaginationState();

  CancelToken? _cancelToken;

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Profile screen disposed');
    _cancelToken = null;
  }

  /// Bumped when tab post lists / paging state change so the grid can rebuild
  /// without tying pagination to the full-screen loading flag.
  final ValueNotifier<int> gridRevision = ValueNotifier(0);

  DateTime? _lastLoadMoreRequestAt;

  /// Prevents duplicate in-flight tab page requests with identical params.
  final Map<int, String?> _lastTabFetchKeys = {};

  /// After gateway/timeouts, block rapid re-fetch (scroll spam).
  DateTime? _profileFetchBackoffUntil;

  ProfileController({ProfileRepository? repository, PostService? postService})
    : _repository = repository ?? ProfileRepository(),
      _postService = postService ?? PostService();

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<ProfileStatsModel> statsNotifier = ValueNotifier(
    const ProfileStatsModel.empty(),
  );
  final ValueNotifier<List<Post>> postsNotifier = ValueNotifier(const []);

  // Local in-memory story and highlight storage
  final ValueNotifier<List<Map<String, dynamic>>> storyList = ValueNotifier([]);
  final ValueNotifier<List<HighlightModel>> highlightList = ValueNotifier([]);

  final ValueNotifier<ProfileModel?> userNotifier = ValueNotifier(null);

  /// Rebuild scrollable profile content (stats + grid). Omits [isLoading] so
  /// tab pagination does not replace the whole screen with a blocking loader.
  late final Listenable contentListenable = Listenable.merge([
    userNotifier,
    statsNotifier,
    postsNotifier,
    gridRevision,
    storyList,
    highlightList,
  ]);

  /// Get user highlights from profile API (for other user profiles)
  List<HighlightModel> get userHighlights => highlightList.value;

  ProfileModel? get user => userNotifier.value;
  set user(ProfileModel? value) => userNotifier.value = value;

  bool _disposed = false;

  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String? _pendingRefreshReason;

  ProfileStatsModel get stats => statsNotifier.value;

  bool get hasLoadedOnce => _hasLoadedOnce;

  void removePostLocal(String postId) {
    if (_disposed) return;

    // Remove from all tab states
    _allTabState.posts.removeWhere((p) => p.id == postId);
    _trendingTabState.posts.removeWhere((p) => p.id == postId);
    _likedTabState.posts.removeWhere((p) => p.id == postId);

    // Update the aligned postsNotifier for tab 0
    postsNotifier.value = List<Post>.from(_allTabState.posts);

    // Re-trigger grid UI rebuild
    gridRevision.value++;

    // Decrement posts count in profile stats if greater than 0
    final currentStats = statsNotifier.value;
    if (currentStats.videosCount > 0) {
      statsNotifier.value = ProfileStatsModel(
        subscribersCount: currentStats.subscribersCount,
        likesCount: currentStats.likesCount,
        videosCount: currentStats.videosCount - 1,
      );
    }

    AppLogger.debug(
      'ProfileController',
      'post_removed_locally',
      data: {'postId': postId},
    );
  }

  /// Throttled near-end scroll: avoids duplicate requests while flinging.
  void requestLoadMoreThrottled(int tabIndex) {
    if (_disposed) return;
    if (tabIndex < 0 || tabIndex > 2) return;
    if (!_getTabState(tabIndex).canLoadMore) return;

    final now = DateTime.now();
    if (_lastLoadMoreRequestAt != null &&
        now.difference(_lastLoadMoreRequestAt!) <
            const Duration(milliseconds: 550)) {
      AppLogger.debug(
        'ProfileController',
        'load_more_throttled',
        data: {'tab': tabIndex},
      );
      return;
    }
    _lastLoadMoreRequestAt = now;
    if (_profileFetchBackoffUntil != null &&
        now.isBefore(_profileFetchBackoffUntil!)) {
      AppLogger.debug(
        'ProfileController',
        'load_more_skipped',
        data: {'reason': 'backoff'},
      );
      return;
    }
    AppLogger.debug(
      'ProfileController',
      'load_more_requested',
      data: {'tab': tabIndex},
    );
    unawaited(loadMorePosts(tabIndex, reason: 'scroll'));
  }

  Future<void> fetchUser({
    bool showLoading = true,
    String reason = 'initial_load',
    bool forceRefresh = false,
  }) {
    AppLogger.debug(
      'ProfileController',
      'fetch_user',
      data: {
        'showLoading': showLoading,
        'reason': reason,
        'forceRefresh': forceRefresh,
      },
    );
    return _refreshProfileData(
      showLoading: showLoading,
      reason: reason,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> refreshCounts({String reason = 'manual_refresh'}) {
    if (reason == 'profile_tab_opened' && _hasLoadedOnce) {
      AppLogger.debug(
        'ProfileController',
        'refresh_skipped',
        data: {'reason': reason},
      );
      return Future.value();
    }
    return _refreshProfileData(showLoading: false, reason: reason);
  }

  Future<void> _refreshProfileData({
    required bool showLoading,
    required String reason,
    bool forceRefresh = false,
  }) async {
    AppLogger.debug(
      'ProfileController',
      'refresh_started',
      data: {
        'showLoading': showLoading,
        'reason': reason,
        'isRefreshing': _isRefreshing,
        'hasLoadedOnce': _hasLoadedOnce,
      },
    );

    if (_isRefreshing) {
      _pendingRefreshReason = reason;
      AppLogger.debug(
        'ProfileController',
        'refresh_queued',
        data: {'reason': reason},
      );
      return;
    }

    _isRefreshing = true;

    if (showLoading && !_hasLoadedOnce && !_disposed) {
      isLoading.value = true;
    }

    try {
      final userData = await _repository.fetchProfileData(
        cancelToken: _getCancelToken(),
        forceRefresh: forceRefresh,
      );

      if (_disposed) {
        AppLogger.debug(
          'ProfileController',
          'refresh_aborted',
          data: {'reason': 'disposed'},
        );
        return;
      }

      final userPayload = _extractUserPayload(userData);

      ProfileModel profile;
      try {
        profile = ProfileModel.fromJson(userData);

        if (profile.id.isEmpty ||
            profile.username.isEmpty ||
            profile.fullName.isEmpty) {
          AppLogger.warning(
            'ProfileController',
            'profile_validation_failed',
            data: {
              'idEmpty': profile.id.isEmpty,
              'usernameEmpty': profile.username.isEmpty,
              'fullNameEmpty': profile.fullName.isEmpty,
            },
          );
        }
      } catch (e) {
        AppLogger.error('ProfileController', 'profile_parse_failed', error: e);
        rethrow;
      }

      final statsPayload = _nestedMap(userPayload['stats']) ?? userPayload;

      ProfileStatsModel stats;
      try {
        stats = ProfileStatsModel.fromJson(
          statsPayload.isNotEmpty ? statsPayload : userData,
        );

        if (stats.subscribersCount < 0 ||
            stats.likesCount < 0 ||
            stats.videosCount < 0) {
          AppLogger.warning(
            'ProfileController',
            'stats_validation_failed',
            data: {
              'subscribersCount': stats.subscribersCount,
              'likesCount': stats.likesCount,
              'videosCount': stats.videosCount,
            },
          );
        }
      } catch (e) {
        AppLogger.error('ProfileController', 'stats_parse_failed', error: e);
        rethrow;
      }

      if (_disposed) {
        AppLogger.debug(
          'ProfileController',
          'refresh_aborted',
          data: {'reason': 'disposed'},
        );
        return;
      }

      user = profile;
      statsNotifier.value = stats;

      // Stories are now handled by unified Story API system, not Profile API
      // Removed story parsing from ProfileController to eliminate dual-system

      // Parse highlights from API response (data['data']['highlights'])
      _parseHighlightsFromResponse(userData);

      _profileFetchBackoffUntil = null;
      _hasLoadedOnce = true;

      _markTabLoadingIfEmpty(0);
      unawaited(_hydratePostsAfterProfileLoad(userData, profile));

      if (_disposed) {
        AppLogger.debug(
          'ProfileController',
          'refresh_aborted',
          data: {'reason': 'disposed'},
        );
        return;
      }

      _profileFetchBackoffUntil = null;
      _hasLoadedOnce = true;
      AppLogger.debug(
        'ProfileController',
        'refresh_completed',
        data: {'reason': reason},
      );
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        AppLogger.debug('ProfileController', 'refresh_cancelled');
        return;
      }
      AppLogger.error('ProfileController', 'refresh_failed', error: error);
      // Keep user data if refresh fails
    } finally {
      _isRefreshing = false;

      if (!_disposed) {
        isLoading.value = false;
      }
    }

    final queued = _pendingRefreshReason;
    if (queued != null && !_disposed) {
      _pendingRefreshReason = null;
      AppLogger.debug(
        'ProfileController',
        'processing_queued_refresh',
        data: {'reason': queued},
      );
      await _refreshProfileData(showLoading: false, reason: queued);
    }
  }

  static String _normalizeHandle(String raw) {
    return raw.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
  }

  Future<List<Post>> _fetchOwnPosts(ProfileModel profile) async {
    try {
      final allPosts = await _postService.getPosts();
      final handle = _normalizeHandle(profile.username);
      final ownPosts = allPosts.where((post) {
        final matchesUserId =
            profile.id.isNotEmpty && post.userId.toString() == profile.id;
        final postHandle = _normalizeHandle(post.username);
        final matchesUsername =
            handle.isNotEmpty && postHandle.isNotEmpty && postHandle == handle;

        return (matchesUserId || matchesUsername) &&
            (post.media.isNotEmpty ||
                post.thumbnailUrl.trim().isNotEmpty ||
                post.gridPreviewUrl.isNotEmpty);
      }).toList();

      AppLogger.debug(
        'ProfileController',
        'own_posts_fetched',
        data: {'count': ownPosts.length, 'feedTotal': allPosts.length},
      );

      return ownPosts;
    } catch (error) {
      AppLogger.error(
        'ProfileController',
        'own_posts_fetch_failed',
        error: error,
      );
      return const [];
    }
  }

  void _markTabLoadingIfEmpty(int tabIndex) {
    if (_disposed) return;
    final state = _getTabState(tabIndex);
    if (state.posts.isNotEmpty || state.isLoading) return;
    _updateTabState(tabIndex, state.copyWith(isLoading: true));
  }

  /// Reads post arrays from the profile payload (root or `data`) when present.

  void _seedTabFromProfilePayload(
    int tabIndex,
    List<Post> posts,
    bool hasNext,
  ) {
    if (_disposed) {
      AppLogger.debug(
        'ProfileController',
        'tab_seed_skipped',
        data: {'reason': 'disposed'},
      );
      return;
    }

    final cleared = _getTabState(tabIndex).reset();
    final nextPage = posts.isEmpty ? 1 : (hasNext ? 2 : 1);

    _updateTabState(
      tabIndex,
      cleared.copyWith(
        posts: posts,
        hasNext: hasNext,
        isLoading: false,
        page: nextPage,
        clearError: true,
      ),
    );

    AppLogger.debug(
      'ProfileController',
      'tab_loaded',
      data: {'tab': tabIndex, 'posts': posts.length, 'hasNext': hasNext},
    );

    PostGridThumbnail.warmupPosts(posts);
  }

  Future<void> _hydratePostsAfterProfileLoad(
    Map<String, dynamic> raw,
    ProfileModel profile,
  ) async {
    if (_disposed) {
      AppLogger.debug(
        'ProfileController',
        'hydration_skipped',
        data: {'reason': 'disposed'},
      );
      return;
    }

    final postsData = raw['data']?['posts'] ?? raw['posts'];

    bool apiParsed = false;

    if (postsData != null && postsData is Map) {
      try {
        // ALL
        final allList = postsData['all']?['results'] ?? [];
        _seedTabFromProfilePayload(
          0,
          (allList as List).map((e) => Post.fromJson(e)).toList(),
          postsData['all']?['has_next'] ?? false,
        );

        // TRENDING
        final trendingList = postsData['trending']?['results'] ?? [];
        _seedTabFromProfilePayload(
          1,
          (trendingList as List).map((e) => Post.fromJson(e)).toList(),
          postsData['trending']?['has_next'] ?? false,
        );

        // LIKED
        final likedPosts = postsData['liked'] ?? postsData['likes'];
        final likedList = likedPosts?['results'] ?? [];
        _seedTabFromProfilePayload(
          2,
          (likedList as List).map((e) => Post.fromJson(e)).toList(),
          likedPosts?['has_next'] ?? false,
        );

        apiParsed = true;
      } catch (e) {
        AppLogger.error(
          'ProfileController',
          'api_posts_parse_failed',
          error: e,
        );
      }
    }

    // fallback only if API failed
    if (!apiParsed) {
      AppLogger.warning('ProfileController', 'using_fallback_posts');
      final own = await _fetchOwnPosts(profile);

      if (_disposed) {
        AppLogger.debug(
          'ProfileController',
          'hydration_aborted',
          data: {'reason': 'disposed'},
        );
        return;
      }

      _seedTabFromProfilePayload(0, own, false);
    }

    final shouldLazyLoadSecondaryTabs = !_disposed;
    if (shouldLazyLoadSecondaryTabs) {
      postsNotifier.value = List<Post>.from(_getTabState(0).posts);
      return;
    }

    // ensure other tabs load if empty
    for (final i in [1, 2]) {
      if (_disposed) {
        AppLogger.debug(
          'ProfileController',
          'hydration_aborted',
          data: {'reason': 'disposed'},
        );
        return;
      }

      if (_getTabState(i).posts.isEmpty) {
        await loadPostsForTab(i, isRefresh: true);
      }
    }

    if (_disposed) {
      AppLogger.debug(
        'ProfileController',
        'hydration_aborted',
        data: {'reason': 'disposed'},
      );
      return;
    }

    postsNotifier.value = List<Post>.from(_getTabState(0).posts);

    AppLogger.debug(
      'ProfileController',
      'hydration_completed',
      data: {
        'all': _allTabState.posts.length,
        'trending': _trendingTabState.posts.length,
        'liked': _likedTabState.posts.length,
      },
    );
  }

  /// Fetches tab posts if the grid has not received data yet (e.g. user switched tab early).
  Future<void> ensureTabLoaded(int tabIndex) async {
    if (_disposed) return;
    if (tabIndex < 0 || tabIndex > 2) return;
    final state = _getTabState(tabIndex);
    if (state.posts.isNotEmpty || state.isLoading) return;
    await loadPostsForTab(tabIndex, isRefresh: true);
  }

  /// Get pagination state for specific tab
  _TabPaginationState _getTabState(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _allTabState;
      case 1:
        return _trendingTabState;
      case 2:
        return _likedTabState;
      default:
        return _allTabState;
    }
  }

  /// Load posts for specific tab with pagination
  Future<void> loadPostsForTab(
    int tabIndex, {
    bool isRefresh = false,
    String reason = 'tab-load',
  }) async {
    if (_disposed) {
      AppLogger.debug(
        'ProfileController',
        'tab_load_skipped',
        data: {'reason': 'disposed'},
      );
      return;
    }

    final currentState = _getTabState(tabIndex);

    // Prevent duplicate calls
    if (currentState.isLoading && !isRefresh) {
      AppLogger.debug(
        'ProfileController',
        'tab_load_skipped',
        data: {'tab': tabIndex, 'reason': 'already_loading'},
      );
      return;
    }

    if (!isRefresh) {
      final requestKey =
          'tab=$tabIndex|page=${currentState.page}|limit=${currentState.limit}';
      if (_lastTabFetchKeys[tabIndex] == requestKey) {
        AppLogger.debug(
          'ProfileController',
          'tab_load_skipped',
          data: {
            'tab': tabIndex,
            'reason': 'duplicate_request',
            'requestKey': requestKey,
          },
        );
        return;
      }
      _lastTabFetchKeys[tabIndex] = requestKey;
    } else {
      _lastTabFetchKeys[tabIndex] = null;
    }

    // Reset state for refresh
    if (isRefresh) {
      final resetState = currentState.reset();
      _updateTabState(tabIndex, resetState);
    }

    final updatedState = _getTabState(
      tabIndex,
    ).copyWith(isLoading: true, clearError: true);
    _updateTabState(tabIndex, updatedState);

    try {
      AppLogger.debug(
        'ProfileController',
        'tab_load_started',
        data: {
          'tab': tabIndex,
          'trigger': reason,
          'page': updatedState.page,
          'limit': updatedState.limit,
          'mode': isRefresh ? 'replace' : 'append',
        },
      );

      final sw = Stopwatch()..start();

      // Build query parameters based on tab
      final queryParams = _buildQueryParams(tabIndex, updatedState);

      // Call API with pagination. Pages beyond the first bypass the GET
      // cache so a subsequent page can never be served a stale/duplicate
      // response for the same query-param cache key.
      final response = await _repository.fetchProfileData(
        allPage: queryParams['allPage'],
        allLimit: queryParams['allLimit'],
        trendingPage: queryParams['trendingPage'],
        trendingLimit: queryParams['trendingLimit'],
        likedPage: queryParams['likedPage'],
        likedLimit: queryParams['likedLimit'],
        cancelToken: _getCancelToken(),
        forceRefresh: updatedState.page > 1,
      );

      if (_disposed) {
        AppLogger.debug(
          'ProfileController',
          'tab_load_aborted',
          data: {'reason': 'disposed'},
        );
        return;
      }

      sw.stop();

      // Parse response
      final posts = _parsePostsFromResponse(response, tabIndex);
      final hasNext = _parseHasNextFromResponse(response, tabIndex);

      final existing = List<Post>.from(_getTabState(tabIndex).posts);
      final uniquePosts = isRefresh
          ? _uniquePosts(posts)
          : _uniquePosts(posts, existingIds: existing.map((p) => p.id).toSet());
      final newPosts = isRefresh ? uniquePosts : [...existing, ...uniquePosts];

      // Trust the server's has_next as-is. A page that happens to contain
      // zero *new* unique posts (stale cache, backend offset drift, etc.)
      // must not be treated as "no more pages" — that would permanently
      // stop pagination even though the server still has more to give.
      final nextPage = isRefresh
          ? (hasNext ? 2 : 1)
          : updatedState.page + 1;

      final finalState = updatedState.copyWith(
        posts: newPosts,
        hasNext: hasNext,
        isLoading: false,
        page: nextPage,
      );

      _updateTabState(tabIndex, finalState);
      _lastTabFetchKeys[tabIndex] = null;

      // Keep [postsNotifier] aligned with the "All" tab only (tab 0).
      if (tabIndex == 0) {
        postsNotifier.value = List<Post>.from(newPosts);
      }

      AppLogger.debug(
        'ProfileController',
        'tab_load_completed',
        data: {
          'tab': tabIndex,
          'newItems': posts.length,
          'total': newPosts.length,
          'hasNext': hasNext,
          'nextPage': nextPage,
          'durationMs': sw.elapsedMilliseconds,
        },
      );

      _profileFetchBackoffUntil = null;
    } catch (e) {
      if (e is DioException) {
        if (CancelToken.isCancel(e)) {
          AppLogger.debug(
            'ProfileController',
            'tab_load_cancelled',
            data: {'tab': tabIndex},
          );
          _lastTabFetchKeys[tabIndex] = null;
          return;
        }
        final code = e.response?.statusCode;
        final transient =
            (code != null && {408, 502, 503, 504}.contains(code)) ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError;
        if (transient) {
          _profileFetchBackoffUntil = DateTime.now().add(
            const Duration(seconds: 12),
          );
          AppLogger.warning(
            'ProfileController',
            'tab_load_transient_failure',
            data: {'tab': tabIndex, 'statusCode': code, 'type': e.type.name},
          );
          final calm = updatedState.copyWith(
            isLoading: false,
            clearError: true,
            hasNext: false,
          );
          _updateTabState(tabIndex, calm);
          _lastTabFetchKeys[tabIndex] = null;
          return;
        }
      }

      AppLogger.error(
        'ProfileController',
        'tab_load_failed',
        data: {'tab': tabIndex},
        error: e,
      );
      _lastTabFetchKeys[tabIndex] = null;

      String errorMessage = e.toString();

      // Handle specific 422 errors
      if (errorMessage.contains('422') ||
          errorMessage.contains('Unprocessable Entity')) {
        if (errorMessage.contains('page') || errorMessage.contains('limit')) {
          errorMessage = 'Invalid pagination parameters. Please try again.';
          final resetState = updatedState.reset();
          _updateTabState(tabIndex, resetState);
          return;
        } else {
          errorMessage = 'Invalid request data. Please try again.';
        }
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('Forbidden')) {
        errorMessage =
            'Access denied. You may not have permission to view this content.';
      } else if (errorMessage.contains('404') ||
          errorMessage.contains('Not Found')) {
        errorMessage = 'Content not found.';
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('Internal Server Error') ||
          errorMessage.contains('504')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (errorMessage.contains('timeout') ||
          errorMessage.contains('connection')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      final errorState = updatedState.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      _updateTabState(tabIndex, errorState);
      _lastTabFetchKeys[tabIndex] = null;
    }
  }

  /// Load more posts for current tab (infinite scroll)
  Future<void> loadMorePosts(int tabIndex, {String reason = 'scroll'}) async {
    final currentState = _getTabState(tabIndex);

    if (!currentState.canLoadMore) {
      AppLogger.debug(
        'ProfileController',
        'load_more_blocked',
        data: {
          'tab': tabIndex,
          'hasNext': currentState.hasNext,
          'isLoading': currentState.isLoading,
        },
      );
      return;
    }

    await loadPostsForTab(tabIndex, isRefresh: false, reason: reason);
  }

  /// Refresh posts for specific tab
  Future<void> refreshTabPosts(int tabIndex) async {
    await loadPostsForTab(tabIndex, isRefresh: true);
  }

  /// Build query parameters based on tab index
  Map<String, int?> _buildQueryParams(int tabIndex, _TabPaginationState state) {
    switch (tabIndex) {
      case 0: // All tab
        return {'allPage': state.page, 'allLimit': state.limit};
      case 1: // Trending tab
        return {'trendingPage': state.page, 'trendingLimit': state.limit};
      case 2: // Liked tab
        return {'likedPage': state.page, 'likedLimit': state.limit};
      default:
        return {};
    }
  }

  /// Parse posts from API response based on tab
  List<Post> _parsePostsFromResponse(
    Map<String, dynamic> response,
    int tabIndex,
  ) {
    try {
      final tabEnvelope = _postsEnvelopeForTab(response, tabIndex);
      final tabResults = tabEnvelope?['results'];
      if (tabResults is List) {
        return _parsePostList(tabResults);
      }

      final keys = <String>[
        _getPostsKeyForTab(tabIndex),
        ..._alternatePostsKeys(tabIndex),
      ];
      final layers = <Map<String, dynamic>>[
        response,
        if (response['data'] is Map)
          Map<String, dynamic>.from(response['data'] as Map),
      ];
      for (final map in layers) {
        for (final postsKey in keys) {
          final postsData = map[postsKey];
          if (postsData is List) {
            return _parsePostList(postsData);
          }
        }
        if (tabIndex == 0 && map['posts'] is List) {
          return _parsePostList(map['posts'] as List);
        }
      }
      return [];
    } catch (e) {
      AppLogger.error(
        'ProfileController',
        'posts_parse_failed',
        data: {'tab': tabIndex},
        error: e,
      );
      return [];
    }
  }

  List<Post> _parsePostList(List<dynamic> rawPosts) {
    return rawPosts
        .whereType<Map>()
        .map((item) => Post.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Post> _uniquePosts(List<Post> posts, {Set<String>? existingIds}) {
    final seenIds = <String>{...?existingIds};
    final unique = <Post>[];

    for (final post in posts) {
      if (post.id.isEmpty) {
        unique.add(post);
        continue;
      }

      if (seenIds.add(post.id)) {
        unique.add(post);
      }
    }

    return unique;
  }

  Map<String, dynamic>? _postsEnvelopeForTab(
    Map<String, dynamic> response,
    int tabIndex,
  ) {
    final tabKeys = switch (tabIndex) {
      0 => const ['all'],
      1 => const ['trending'],
      2 => const ['liked', 'likes'],
      _ => const <String>[],
    };
    if (tabKeys.isEmpty) return null;

    final data = _nestedMap(response['data']);
    final postRoots = <Map<String, dynamic>?>[
      _nestedMap(response['posts']),
      _nestedMap(data?['posts']),
    ];

    for (final postsRoot in postRoots) {
      if (postsRoot == null) continue;
      for (final tabKey in tabKeys) {
        final envelope = _nestedMap(postsRoot[tabKey]);
        if (envelope != null) return envelope;
      }
    }

    return null;
  }

  List<String> _alternatePostsKeys(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return ['allPosts', 'user_posts', 'userPosts'];
      case 1:
        return ['trendingPosts'];
      case 2:
        return ['likedPosts'];
      default:
        return const [];
    }
  }

  /// Parse has_next from API response based on tab
  bool _parseHasNextFromResponse(Map<String, dynamic> response, int tabIndex) {
    try {
      final tabEnvelope = _postsEnvelopeForTab(response, tabIndex);
      final envelopeHasNext =
          tabEnvelope?['has_next'] ?? tabEnvelope?['hasNext'];
      if (envelopeHasNext is bool) return envelopeHasNext;
      if (envelopeHasNext is int) return envelopeHasNext == 1;
      if (envelopeHasNext is String) {
        return envelopeHasNext.toLowerCase() == 'true';
      }
      if (tabEnvelope != null && tabEnvelope.containsKey('next')) {
        return tabEnvelope['next'] != null;
      }

      bool? read(Map<String, dynamic> map) {
        final hasNextKey = _getHasNextKeyForTab(tabIndex);
        final keys = <String>[
          hasNextKey,
          if (tabIndex == 0) ...['allHasNext', 'all_has_next'],
          if (tabIndex == 1) ...['trendingHasNext', 'trending_has_next'],
          if (tabIndex == 2) ...['likedHasNext', 'liked_has_next'],
        ];
        for (final k in keys) {
          final hasNext = map[k];
          if (hasNext is bool) return hasNext;
          if (hasNext is int) return hasNext == 1;
          if (hasNext is String) return hasNext.toLowerCase() == 'true';
        }
        final commonHasNext = map['has_next'] ?? map['hasNext'];
        if (commonHasNext is bool) return commonHasNext;
        if (commonHasNext is int) return commonHasNext == 1;
        if (commonHasNext is String) {
          return commonHasNext.toLowerCase() == 'true';
        }
        return null;
      }

      return read(response) ??
          (response['data'] is Map
              ? read(Map<String, dynamic>.from(response['data'] as Map))
              : null) ??
          false;
    } catch (e) {
      AppLogger.error(
        'ProfileController',
        'has_next_parse_failed',
        data: {'tab': tabIndex},
        error: e,
      );
      return false;
    }
  }

  /// Get posts key for specific tab
  String _getPostsKeyForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'all_posts';
      case 1:
        return 'trending_posts';
      case 2:
        return 'liked_posts';
      default:
        return 'posts';
    }
  }

  /// Get has_next key for specific tab
  String _getHasNextKeyForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'all_has_next';
      case 1:
        return 'trending_has_next';
      case 2:
        return 'liked_has_next';
      default:
        return 'has_next';
    }
  }

  /// Update specific tab state
  void _updateTabState(int tabIndex, _TabPaginationState newState) {
    if (_disposed) return;
    switch (tabIndex) {
      case 0:
        _allTabState.page = newState.page;
        _allTabState.limit = newState.limit;
        _allTabState.posts = newState.posts;
        _allTabState.hasNext = newState.hasNext;
        _allTabState.isLoading = newState.isLoading;
        _allTabState.error = newState.error;
        break;
      case 1:
        _trendingTabState.page = newState.page;
        _trendingTabState.limit = newState.limit;
        _trendingTabState.posts = newState.posts;
        _trendingTabState.hasNext = newState.hasNext;
        _trendingTabState.isLoading = newState.isLoading;
        _trendingTabState.error = newState.error;
        break;
      case 2:
        _likedTabState.page = newState.page;
        _likedTabState.limit = newState.limit;
        _likedTabState.posts = newState.posts;
        _likedTabState.hasNext = newState.hasNext;
        _likedTabState.isLoading = newState.isLoading;
        _likedTabState.error = newState.error;
        break;
    }
    gridRevision.value = gridRevision.value + 1;
  }

  /// Get posts for specific tab
  List<Post> getPostsForTab(int tabIndex) {
    return _getTabState(tabIndex).posts;
  }

  /// Get loading state for specific tab
  bool isLoadingTab(int tabIndex) {
    return _getTabState(tabIndex).isLoading;
  }

  /// Get error for specific tab
  String? getErrorForTab(int tabIndex) {
    return _getTabState(tabIndex).error;
  }

  /// Check if tab can load more posts
  bool canLoadMoreForTab(int tabIndex) {
    return _getTabState(tabIndex).canLoadMore;
  }

  /// Get current page for tab
  int getPageForTab(int tabIndex) {
    return _getTabState(tabIndex).page;
  }

  /// Get limit for tab
  int getLimitForTab(int tabIndex) {
    return _getTabState(tabIndex).limit;
  }

  void dispose() {
    cancelActiveRequests();
    _disposed = true;
    isLoading.dispose();
    userNotifier.dispose();
    statsNotifier.dispose();
    postsNotifier.dispose();
    gridRevision.dispose();
    storyList.dispose();
    highlightList.dispose();
  }

  Map<String, dynamic> _extractUserPayload(Map<String, dynamic> source) {
    final candidates = <dynamic>[
      source['user'],
      _nestedMap(source['data'])?['user'],
      source['profile'],
      _nestedMap(source['data'])?['profile'],
      source['data'],
      source,
    ];

    for (final candidate in candidates) {
      final map = _nestedMap(candidate);
      if (map == null) continue;
      if (_looksLikeUserPayload(map)) {
        return map;
      }
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  bool _looksLikeUserPayload(Map<String, dynamic> value) {
    return value.containsKey('username') ||
        value.containsKey('full_name') ||
        value.containsKey('profile_picture') ||
        value.containsKey('id') ||
        value.containsKey('user_id');
  }

  // Story-related methods removed - now handled by unified Story API system
  // _extractStoriesData, _handleMissingStoriesFromProfile, _isCurrentProfileSyncedWithStoryState, _parseStoryCreatedAt

  // ========== LOCAL STORY & HIGHLIGHT LOGIC ==========

  /// Add a new story to the local storyList
  void addStory({required String imageUrl, String? username}) {
    if (_disposed) return;

    final story = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'imageUrl': imageUrl,
      'username': username ?? user?.username ?? 'User',
      'hasSeen': false,
    };

    final currentStories = List<Map<String, dynamic>>.from(storyList.value);
    currentStories.add(story);
    storyList.value = currentStories;

    AppLogger.debug(
      'ProfileController',
      'story_added',
      data: {'storyId': story['id'], 'total': storyList.value.length},
    );
  }

  /// Mark a story as seen
  void markStoryAsSeen(String storyId) {
    if (_disposed) return;

    final currentStories = List<Map<String, dynamic>>.from(storyList.value);
    final index = currentStories.indexWhere((s) => s['id'] == storyId);

    if (index != -1) {
      currentStories[index]['hasSeen'] = true;
      storyList.value = currentStories;
      AppLogger.debug(
        'ProfileController',
        'story_marked_seen',
        data: {'storyId': storyId},
      );
    }
  }

  /// Create a highlight from a story
  void addToHighlight({required String storyId, required String title}) {
    if (_disposed) return;

    final currentStories = storyList.value;
    final story = currentStories.firstWhere(
      (s) => s['id'] == storyId,
      orElse: () => {},
    );

    if (story.isEmpty) {
      AppLogger.warning(
        'ProfileController',
        'story_not_found',
        data: {'storyId': storyId},
      );
      return;
    }

    // Create a HighlightModel from the story data
    final highlightModel = HighlightModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      storiesCount: 1,
      coverMediaUrl: story['imageUrl'] ?? '',
      createdAt: DateTime.now().toIso8601String(),
      stories: [
        HighlightStoryRef(id: storyId, mediaUrl: story['imageUrl'] ?? ''),
      ],
    );

    final currentHighlights = List<HighlightModel>.from(highlightList.value);
    currentHighlights.add(highlightModel);
    highlightList.value = currentHighlights;

    AppLogger.debug(
      'ProfileController',
      'highlight_created',
      data: {
        'title': highlightModel.title,
        'total': highlightList.value.length,
      },
    );
  }

  /// Add a story to an existing highlight
  void addStoryToHighlight({
    required String highlightId,
    required String storyId,
  }) {
    if (_disposed) return;

    final currentStories = storyList.value;
    final story = currentStories.firstWhere(
      (s) => s['id'] == storyId,
      orElse: () => {},
    );

    if (story.isEmpty) {
      AppLogger.warning(
        'ProfileController',
        'story_not_found',
        data: {'storyId': storyId},
      );
      return;
    }

    final currentHighlights = List<HighlightModel>.from(highlightList.value);
    final index = currentHighlights.indexWhere((h) => h.id == highlightId);

    if (index != -1) {
      final highlight = currentHighlights[index];
      final stories = List<HighlightStoryRef>.from(highlight.stories);
      stories.add(
        HighlightStoryRef(id: storyId, mediaUrl: story['imageUrl'] ?? ''),
      );

      // Create new highlight with updated stories
      currentHighlights[index] = HighlightModel(
        id: highlight.id,
        title: highlight.title,
        storiesCount: stories.length,
        coverMediaUrl: highlight.coverMediaUrl,
        createdAt: highlight.createdAt,
        stories: stories,
      );

      highlightList.value = currentHighlights;
      AppLogger.debug(
        'ProfileController',
        'story_added_to_highlight',
        data: {'highlightId': highlightId, 'storyId': storyId},
      );
    }
  }

  /// Get stories from highlights directly (alternative approach)
  List<Map<String, dynamic>> get storiesFromHighlights {
    if (_disposed) return [];

    final allStories = <Map<String, dynamic>>[];

    for (final highlight in highlightList.value) {
      if (highlight.stories.isNotEmpty) {
        // Convert HighlightStoryRef to Map format for compatibility
        final processedStories = highlight.stories.map((storyRef) {
          return <String, dynamic>{
            'id': storyRef.id,
            'imageUrl': storyRef.mediaUrl.isNotEmpty
                ? storyRef.mediaUrl
                : 'https://via.placeholder.com/60x60',
            'mediaUrl': storyRef.mediaUrl,
            'username': user?.username ?? 'User',
            'hasSeen': false,
            'mediaKind': 'image',
            'caption': null,
          };
        }).toList();

        allStories.addAll(processedStories);
      }
    }

    AppLogger.debug(
      'ProfileController',
      'stories_from_highlights',
      data: {
        'stories': allStories.length,
        'highlights': highlightList.value.length,
      },
    );
    return allStories;
  }

  /// Parse highlights from API response (data['data']['highlights'])
  void _parseHighlightsFromResponse(Map<String, dynamic> userData) {
    try {
      final data = userData['data'];
      if (data is! Map<String, dynamic>) {
        highlightList.value = [];
        return;
      }

      final highlightsData = data['highlights'];
      if (highlightsData == null) {
        highlightList.value = [];
        return;
      }

      if (highlightsData is! List) {
        AppLogger.warning(
          'ProfileController',
          'highlights_unexpected_type',
          data: {'actualType': highlightsData.runtimeType.toString()},
        );
        highlightList.value = [];
        return;
      }

      final parsedHighlights = highlightsData
          .whereType<Map<String, dynamic>>()
          .map((item) => HighlightModel.fromJson(item))
          .where((highlight) => highlight.id.isNotEmpty)
          .toList();

      highlightList.value = parsedHighlights;

      AppLogger.debug(
        'ProfileController',
        'highlights_parsed',
        data: {'count': parsedHighlights.length},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'ProfileController',
        'highlights_parse_failed',
        error: e,
        stackTrace: stackTrace,
      );
      highlightList.value = [];
    }
  }

  /// Reset all profile controller data on logout
  void reset() {
    AppLogger.debug('ProfileController', 'reset_started');

    user = null;
    statsNotifier.value = const ProfileStatsModel.empty();
    _allTabState.posts.clear();
    _allTabState.page = 1;
    _allTabState.hasNext = true;
    _trendingTabState.posts.clear();
    _trendingTabState.page = 1;
    _trendingTabState.hasNext = true;
    _likedTabState.posts.clear();
    _likedTabState.page = 1;
    _likedTabState.hasNext = true;
    _isRefreshing = false;
    _hasLoadedOnce = false;
    _profileFetchBackoffUntil = null;
    highlightList.value = [];
    storyList.value = [];
    postsNotifier.value = [];
    gridRevision.value = 0;

    AppLogger.debug('ProfileController', 'reset_completed');
  }
}
