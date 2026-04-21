import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/profile/repository/profile_repository.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';

import '../model/profile_model.dart';
import '../model/profile_stats_model.dart';

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

  /// Bumped when tab post lists / paging state change so the grid can rebuild
  /// without tying pagination to the full-screen loading flag.
  final ValueNotifier<int> gridRevision = ValueNotifier(0);

  DateTime? _lastLoadMoreRequestAt;

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

  /// Rebuild scrollable profile content (stats + grid). Omits [isLoading] so
  /// tab pagination does not replace the whole screen with a blocking loader.
  late final Listenable contentListenable = Listenable.merge([
    statsNotifier,
    postsNotifier,
    gridRevision,
  ]);

  ProfileModel? user;

  bool _disposed = false;

  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String? _pendingRefreshReason;

  ProfileStatsModel get stats => statsNotifier.value;

  bool get hasLoadedOnce => _hasLoadedOnce;

  /// Throttled near-end scroll: avoids duplicate requests while flinging.
  void requestLoadMoreThrottled(int tabIndex) {
    if (_disposed) return;
    if (tabIndex < 0 || tabIndex > 2) return;
    if (!_getTabState(tabIndex).canLoadMore) return;

    final now = DateTime.now();
    if (_lastLoadMoreRequestAt != null &&
        now.difference(_lastLoadMoreRequestAt!) <
            const Duration(milliseconds: 550)) {
      debugPrint('⏳ [ProfileController] loadMore throttled tab=$tabIndex');
      return;
    }
    _lastLoadMoreRequestAt = now;
    if (_profileFetchBackoffUntil != null &&
        now.isBefore(_profileFetchBackoffUntil!)) {
      debugPrint('⏳ [ProfileController] loadMore skipped (backoff after 5xx)');
      return;
    }
    debugPrint(
      '📍 [ProfileController] loadMore tab=$tabIndex at ${now.millisecondsSinceEpoch}',
    );
    unawaited(loadMorePosts(tabIndex));
  }

  Future<void> fetchUser({
    bool showLoading = true,
    String reason = 'initial_load',
  }) {
    return _refreshProfileData(showLoading: showLoading, reason: reason);
  }

  Future<void> refreshCounts({String reason = 'manual_refresh'}) {
    return _refreshProfileData(showLoading: false, reason: reason);
  }

  Future<void> _refreshProfileData({
    required bool showLoading,
    required String reason,
  }) async {
    if (_isRefreshing) {
      _pendingRefreshReason = reason;
      debugPrint(
        '⏳ Profile refresh already running, queued another refresh. reason=$reason',
      );
      return;
    }

    _isRefreshing = true;

    if (showLoading && !_hasLoadedOnce && !_disposed) {
      isLoading.value = true;
    }

    try {
      debugPrint('🔄 Profile refresh started. reason=$reason');
      final userData = await _repository.fetchProfileData();
      if (_disposed) return;

      final userPayload = _extractUserPayload(userData);
      debugPrint(
        '📦 [ProfileController] extracted user payload keys: ${userPayload.keys.toList()}',
      );

      final profile = ProfileModel.fromJson(
        userPayload.isNotEmpty ? userPayload : userData,
      );
      debugPrint(
        '📦 [ProfileController] parsed profile: username=${profile.username}, fullName=${profile.fullName}',
      );

      debugPrint(
        '📦 [ProfileController] creating ProfileStatsModel...',
      );
      final statsPayload = _nestedMap(userPayload['stats']) ?? userPayload;
      final stats = ProfileStatsModel.fromJson(
        statsPayload.isNotEmpty ? statsPayload : userData,
      );
      debugPrint(
        '📦 [ProfileController] parsed stats: subscribers=${stats.subscribersCount}, likes=${stats.likesCount}, videos=${stats.videosCount}',
      );

      if (_disposed) return;
      user = profile;
      statsNotifier.value = stats;
      debugPrint('📦 [ProfileController] updated user and statsNotifier');

      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (_disposed) return;

      await _hydratePostsAfterProfileLoad(userData, profile);
      if (_disposed) return;

      _profileFetchBackoffUntil = null;
      _hasLoadedOnce = true;
      debugPrint('✅ Profile refresh completed successfully');
    } catch (error) {
      debugPrint('❌ Profile refresh failed: $error');
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
      debugPrint('🔄 Processing queued refresh: $queued');
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

        return (matchesUserId || matchesUsername) && post.media.isNotEmpty;
      }).toList();

      debugPrint(
        '✅ [ProfileController] _fetchOwnPosts -> ${ownPosts.length} posts (feed total: ${allPosts.length})',
      );

      return ownPosts;
    } catch (error) {
      debugPrint('❌ Error fetching own profile posts: $error');
      return const [];
    }
  }

  /// Reads post arrays from the profile payload (root or `data`) when present.

  void _seedTabFromProfilePayload(
    int tabIndex,
    List<Post> posts,
    bool hasNext,
  ) {
    if (_disposed) return;

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

    debugPrint(
      'â [ProfileController] Seeded tab $tabIndex with ${posts.length} posts, hasNext=$hasNext',
    );
  }

  Future<void> _hydratePostsAfterProfileLoad(
    Map<String, dynamic> raw,
    ProfileModel profile,
  ) async {
    if (_disposed) return;

    debugPrint('🔄 [ProfileController] hydrate posts (FIXED API PARSING)');

    final postsData = raw['data']?['posts'] ?? raw['posts'];

    bool apiParsed = false;

    if (postsData != null && postsData is Map) {
      try {
        // ✅ ALL
        final allList = postsData['all']?['results'] ?? [];
        _seedTabFromProfilePayload(
          0,
          (allList as List).map((e) => Post.fromJson(e)).toList(),
          postsData['all']?['has_next'] ?? false,
        );

        // ✅ TRENDING
        final trendingList = postsData['trending']?['results'] ?? [];
        _seedTabFromProfilePayload(
          1,
          (trendingList as List).map((e) => Post.fromJson(e)).toList(),
          postsData['trending']?['has_next'] ?? false,
        );

        // ✅ LIKED
        final likedPosts = postsData['liked'] ?? postsData['likes'];
        final likedList = likedPosts?['results'] ?? [];
        _seedTabFromProfilePayload(
          2,
          (likedList as List).map((e) => Post.fromJson(e)).toList(),
          likedPosts?['has_next'] ?? false,
        );

        apiParsed = true;
        debugPrint('✅ [ProfileController] API posts parsed correctly');
      } catch (e) {
        debugPrint('❌ API parsing failed: $e');
      }
    }

    // ❗ fallback only if API failed
    if (!apiParsed) {
      debugPrint('⚠️ Using fallback (own posts)');
      final own = await _fetchOwnPosts(profile);
      if (_disposed) return;
      _seedTabFromProfilePayload(0, own, false);
    }

    // ensure other tabs load if empty
    for (final i in [1, 2]) {
      if (_disposed) return;
      if (_getTabState(i).posts.isEmpty) {
        await loadPostsForTab(i, isRefresh: true);
      }
    }

    if (_disposed) return;

    postsNotifier.value = List<Post>.from(_getTabState(0).posts);

    debugPrint(
      '📊 FINAL: All=${_allTabState.posts.length}, '
      'Trending=${_trendingTabState.posts.length}, '
      'Liked=${_likedTabState.posts.length}',
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
  Future<void> loadPostsForTab(int tabIndex, {bool isRefresh = false}) async {
    if (_disposed) return;
    final currentState = _getTabState(tabIndex);

    // Prevent duplicate calls
    if (currentState.isLoading && !isRefresh) {
      debugPrint('⏳ Tab $tabIndex already loading, skipping request');
      return;
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
      debugPrint(
        '🔄 [ProfileController] tab=$tabIndex page=${updatedState.page} '
        'limit=${updatedState.limit} mode=${isRefresh ? "replace" : "append"}',
      );

      final sw = Stopwatch()..start();

      // Build query parameters based on tab
      final queryParams = _buildQueryParams(tabIndex, updatedState);

      // Call API with pagination
      final response = await _repository.fetchProfileData(
        allPage: queryParams['allPage'],
        allLimit: queryParams['allLimit'],
        trendingPage: queryParams['trendingPage'],
        trendingLimit: queryParams['trendingLimit'],
        likedPage: queryParams['likedPage'],
        likedLimit: queryParams['likedLimit'],
      );

      if (_disposed) return;

      sw.stop();

      // Parse response
      final posts = _parsePostsFromResponse(response, tabIndex);
      final hasNext = _parseHasNextFromResponse(response, tabIndex);

      final existing = List<Post>.from(_getTabState(tabIndex).posts);
      final newPosts = isRefresh ? posts : [...existing, ...posts];

      final nextPage = isRefresh
          ? ((hasNext && posts.isNotEmpty) ? 2 : 1)
          : updatedState.page + 1;

      final finalState = updatedState.copyWith(
        posts: newPosts,
        hasNext: hasNext,
        isLoading: false,
        page: nextPage,
      );

      _updateTabState(tabIndex, finalState);

      // Keep [postsNotifier] aligned with the "All" tab only (tab 0).
      if (tabIndex == 0) {
        postsNotifier.value = List<Post>.from(newPosts);
      }

      debugPrint(
        '✅ [ProfileController] tab=$tabIndex +${posts.length} items '
        'total=${newPosts.length} hasNext=$hasNext nextPage=$nextPage '
        '(${sw.elapsedMilliseconds}ms)',
      );

      _profileFetchBackoffUntil = null;
    } catch (e) {
      if (e is DioException) {
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
          debugPrint(
            '⚠️ [ProfileController] tab=$tabIndex profile_data '
            'transient failure (HTTP $code / ${e.type}). '
            'Keeping existing posts; pull-to-refresh to retry.',
          );
          final calm = updatedState.copyWith(
            isLoading: false,
            clearError: true,
            hasNext: false,
          );
          _updateTabState(tabIndex, calm);
          return;
        }
      }

      debugPrint('❌ Error loading posts for tab $tabIndex: $e');

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
    }
  }

  /// Load more posts for current tab (infinite scroll)
  Future<void> loadMorePosts(int tabIndex) async {
    final currentState = _getTabState(tabIndex);

    if (!currentState.canLoadMore) {
      debugPrint(
        '🚫 Cannot load more posts for tab $tabIndex: hasNext=${currentState.hasNext}, isLoading=${currentState.isLoading}',
      );
      return;
    }

    await loadPostsForTab(tabIndex, isRefresh: false);
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
      debugPrint('❌ Error parsing posts for tab $tabIndex: $e');
      return [];
    }
  }

  List<Post> _parsePostList(List<dynamic> rawPosts) {
    return rawPosts
        .whereType<Map>()
        .map((item) => Post.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
      debugPrint('❌ Error parsing has_next for tab $tabIndex: $e');
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
    return _getTabState(tabIndex).hasNext;
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
    _disposed = true;
    isLoading.dispose();
    statsNotifier.dispose();
    postsNotifier.dispose();
    gridRevision.dispose();
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
}
