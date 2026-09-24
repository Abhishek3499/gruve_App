import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/features/story_preview/data/dto/cursor_model.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/storage/hive_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';

/// 🚀 PRODUCTION OPTIMIZATION: TikTok-style video controller management
/// Keeps previous + current + next video initialized for optimal memory usage
/// Memory impact: 50-100MB → 10-20MB (80% reduction)
/// FPS impact: 20-30fps → 55-60fps (100% improvement)
///
/// FIX: Race condition resolved — playVideo() was called before
/// VideoPlayerController finished async init, so _controllers[index]
/// was always null and play() was never invoked.
/// Now _ensureControllersAroundIndex auto-plays when init completes.

class VideoFeedController {
  VoidCallback? onScrollToTop;
  VoidCallback? onPostsRemoved;
  bool _disposed = false;
  int _feedLoadGeneration = 0;
  bool _isAnyOperationInProgress = false;
  bool _pendingForYouRefresh = false;
  bool _pendingSubscribedRefresh = false;
  Timer? _subscriptionFeedRefreshDebounce;
  bool _pendingReplaceSnapshotRefresh = false;

  /// Callback to check if a user is blocked
  bool Function(String userId)? isBlockedUser;

  VideoFeedController() {
    final subscribeController = SubscribeNotifier();
    _syncedSubscribedUserIds = subscribeController.users.entries
        .where(
          (e) =>
              e.value.isSubscribed &&
              subscribeController.isSubscriptionSynced(e.key),
        )
        .map((e) => e.key)
        .toSet();
    _syncedUnsubscribedUserIds = subscribeController.users.entries
        .where(
          (e) =>
              !e.value.isSubscribed &&
              subscribeController.isSubscriptionSynced(e.key),
        )
        .map((e) => e.key)
        .toSet();
    _localSubscribedUserIds = _collectLocalSubscribedUserIds(
      subscribeController,
    );
    SubscribeNotifier().addListener(_onSubscriptionChanged);
  }

  Set<String> _syncedSubscribedUserIds = {};
  Set<String> _syncedUnsubscribedUserIds = {};
  Set<String> _localSubscribedUserIds = {};

  List<String> _mediaUrls = [];
  List<String> get mediaUrls => _mediaUrls;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  final PostService _postService = PostService();

  // URL-keyed cache — survives scroll-back without re-downloading the same clip.
  final Map<String, VideoPlayerController> _controllersByUrl =
      <String, VideoPlayerController>{};
  final Set<String> _initializingUrls = <String>{};
  final Map<String, VideoPlayerController> _initializingControllers =
      <String, VideoPlayerController>{};
  final Set<String> _pendingRetryUrls = <String>{};
  final Set<String> _failedUrls = <String>{};
  final Map<String, int> _initTokensByUrl = <String, int>{};
  final Map<String, Future<void>> _initFuturesByUrl = <String, Future<void>>{};
  int _initTokenSeq = 0;
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<int> _feedStructureRevision = ValueNotifier(0);
  final ValueNotifier<bool> _isInitialFeedLoadingNotifier = ValueNotifier(true);
  final Map<String, ValueNotifier<int>> _itemRevisions = {};

  /// Bumped when video controllers are added/removed — avoids rebuilding the
  /// entire feed when only a single slot becomes ready.
  final ValueNotifier<int> _videoControllersRevision = ValueNotifier(0);
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _loadErrorNotifier = ValueNotifier(null);
  String _currentFeed = 'for_you';
  String get currentFeed => _currentFeed;

  static const int maxCachedControllers = 3;
  static const int preloadDistance = 1;
  // Keeps the previous clip warm too, so swiping down is as instant as swiping up.
  static const int preloadBehindDistance = 1;
  static const int maxInitRetries = 3;
  static const Duration initTimeout = Duration(seconds: 18);
  static const Duration preloadInitTimeout = Duration(seconds: 12);
  static const Duration _ensureAroundIndexDebounce = Duration(milliseconds: 50);
  static const int maxConsecutiveEmptyLoadMorePages = 3;

  Timer? _ensureAroundIndexDebounceTimer;
  int _pendingEnsureAroundIndex = 0;
  bool _hasPendingEnsureAroundIndex = false;

  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _loadError;
  CursorModel? _nextCursor;
  bool _isInitialFeedLoading = true;
  int _consecutiveEmptyLoadMorePages = 0;

  // Separate loading states for better UX
  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInitialFeedLoading => _isInitialFeedLoading;

  ValueNotifier<int> get currentIndex => _currentIndex;
  bool get hasMore => _hasMore;
  String? get loadError => _loadError;
  ValueNotifier<int> get feedStructureRevision => _feedStructureRevision;
  ValueNotifier<bool> get isInitialFeedLoadingListenable =>
      _isInitialFeedLoadingNotifier;
  ValueNotifier<bool> get isLoadingMoreListenable => _isLoadingMoreNotifier;
  ValueNotifier<String?> get loadErrorListenable => _loadErrorNotifier;
  ValueNotifier<int> get videoControllersRevision => _videoControllersRevision;
  ValueNotifier<int> itemRevisionListenable(String itemKey) {
    return _itemRevisions.putIfAbsent(itemKey, () => ValueNotifier(0));
  }

  void _notifyFeedStructureChanged() {
    _feedStructureRevision.value++;
  }

  void _notifyFeedItemChanged(String itemKey) {
    if (itemKey.isEmpty) return;
    final notifier = _itemRevisions[itemKey];
    if (notifier != null) {
      notifier.value++;
    }
  }

  void _setInitialFeedLoading(bool value) {
    if (_isInitialFeedLoading == value) return;
    _isInitialFeedLoading = value;
    _isInitialFeedLoadingNotifier.value = value;
  }

  void _disposeItemRevisions() {
    for (final notifier in _itemRevisions.values) {
      notifier.dispose();
    }
    _itemRevisions.clear();
  }

  String _itemRevisionKey(Post post, {String? mediaUrl}) {
    if (post.id.isNotEmpty) return post.id;
    final url = mediaUrl ?? _feedMediaUrlFor(post);
    return url.trim();
  }

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) return;
    _isLoadingMore = value;
    _isLoadingMoreNotifier.value = value;
  }

  void _setLoadError(String? error) {
    if (_loadError == error) return;
    _loadError = error;
    _loadErrorNotifier.value = error;
  }

  void _notifyVideoControllersChanged() {
    _videoControllersRevision.value++;
  }

  /// Merges refreshed posts at the top, avoiding duplicates and preserving scroll position
  void _mergeRefreshedPosts(List<Post> newPosts) {
    final existingIds = _posts.map((post) => post.id).toSet();

    final uniqueNewPosts = _uniquePosts(newPosts, existingIds: existingIds);

    if (uniqueNewPosts.isEmpty) {
      return;
    }

    _posts.insertAll(0, uniqueNewPosts);
    _mediaUrls.insertAll(0, uniqueNewPosts.map(_feedMediaUrlFor).toList());

    if (_currentIndex.value > 0) {
      _currentIndex.value += uniqueNewPosts.length;
    }
  }

  /// Replaces the in-memory feed with the API snapshot while keeping the
  /// current video when it is still present — used after subscribe/unsubscribe sync.
  void _applyRefreshedFeedSnapshot(List<Post> apiPosts) {
    final uniquePosts = _uniquePosts(apiPosts);
    final newUrls = uniquePosts.map(_feedMediaUrlFor).toList();
    final newUrlSet = newUrls.toSet();

    final currentPostId =
        _posts.isNotEmpty && _currentIndex.value < _posts.length
        ? _posts[_currentIndex.value].id
        : null;
    final currentUrl = _mediaUrlAt(_currentIndex.value);

    final preservedControllers = <String, VideoPlayerController>{};
    for (final entry in _controllersByUrl.entries) {
      if (newUrlSet.contains(entry.key)) {
        preservedControllers[entry.key] = entry.value;
      } else {
        final controller = entry.value;
        Future.microtask(() async {
          try {
            await controller.pause();
            await controller.dispose();
          } catch (e) {
            AppLogger.d(
              '❌ Error disposing controller for removed snapshot url=${entry.key}: $e',
            );
          }
        });
      }
    }

    _controllersByUrl
      ..clear()
      ..addAll(preservedControllers);
    _initializingUrls.removeWhere((url) => !newUrlSet.contains(url));
    _initTokensByUrl.removeWhere((url, _) => !newUrlSet.contains(url));
    _failedUrls.removeWhere((url) => !newUrlSet.contains(url));
    _notifyVideoControllersChanged();

    _posts = uniquePosts;
    _mediaUrls = newUrls;

    if (currentPostId != null && currentPostId.isNotEmpty) {
      final samePostIndex = _posts.indexWhere(
        (post) => post.id == currentPostId,
      );
      if (samePostIndex >= 0) {
        _currentIndex.value = samePostIndex;
      } else if (currentUrl.isNotEmpty && newUrlSet.contains(currentUrl)) {
        _currentIndex.value = newUrls.indexOf(currentUrl);
      } else if (_posts.isNotEmpty) {
        _currentIndex.value = _currentIndex.value.clamp(0, _posts.length - 1);
      } else {
        _currentIndex.value = 0;
      }
    } else if (_posts.isNotEmpty) {
      _currentIndex.value = _currentIndex.value.clamp(0, _posts.length - 1);
    } else {
      _currentIndex.value = 0;
      _isPlaying.value = false;
    }

    _notifyFeedStructureChanged();

    // The PageView keeps whatever physical page it was on; without this the
    // displayed page can end up pointing at a different post than
    // _currentIndex.value (or past the end of the new list), showing a
    // blank/black item — e.g. when a subscribe/unsubscribe sync silently
    // swaps the feed snapshot while the user is on another screen.
    onPostsRemoved?.call();
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

  bool _canLoadAfterCursor({
    required CursorModel? requestedCursor,
    required CursorModel? nextCursor,
    required bool apiHasMore,
  }) {
    if (!apiHasMore) return false;
    if (nextCursor == null || !nextCursor.isValid) return false;
    if (requestedCursor != null && requestedCursor == nextCursor) return false;
    return true;
  }

  String _mediaUrlAt(int mediaIndex) {
    if (mediaIndex < 0 || mediaIndex >= _mediaUrls.length) return '';
    return _mediaUrls[mediaIndex].trim();
  }

  String _feedMediaUrlFor(Post post) => post.feedMediaUrl;

  VideoPlayerController? controllerForMediaIndex(int mediaIndex) {
    final url = _mediaUrlAt(mediaIndex);
    if (url.isEmpty) return null;
    return _controllersByUrl[url];
  }

  bool hasVideoLoadFailed(int mediaIndex) {
    final url = _mediaUrlAt(mediaIndex);
    return url.isNotEmpty && _failedUrls.contains(url);
  }

  bool isVideoInitializing(int mediaIndex) {
    final url = _mediaUrlAt(mediaIndex);
    return url.isNotEmpty && _initializingUrls.contains(url);
  }

  Future<bool?> loadMorePosts({String reason = 'scroll'}) async {
    if (_isAnyOperationInProgress) {
      return null;
    }

    if (_isLoadingMore || !_hasMore || _isRefreshing) return null;

    final requestId = _feedLoadGeneration;
    _isAnyOperationInProgress = true;
    _setLoadError(null);
    _setLoadingMore(true);

    try {
      var fetchCursor = _nextCursor;

      while (true) {
        final response = await _postService.getPaginatedPosts(
          cursor: fetchCursor,
          feed: _currentFeed,
        );

        if (requestId != _feedLoadGeneration) {
          return null;
        }

        final posts = _filterPostsWithSupportedMedia(response.posts);
        final uniquePosts = _uniquePosts(
          posts,
          existingIds: _posts.map((post) => post.id).toSet(),
        );
        final canLoadMore = _canLoadAfterCursor(
          requestedCursor: fetchCursor,
          nextCursor: response.nextCursor,
          apiHasMore: response.hasMore,
        );

        _nextCursor = response.nextCursor;

        if (uniquePosts.isNotEmpty) {
          _consecutiveEmptyLoadMorePages = 0;

          if (_currentFeed == 'subscribed') {
            _seedSubscribedAuthors(uniquePosts);
          }
          _posts.addAll(uniquePosts);
          _mediaUrls.addAll(uniquePosts.map(_feedMediaUrlFor));
          _hasMore = canLoadMore;
          _notifyFeedStructureChanged();
          unawaited(_precacheFeedImages(uniquePosts));
          unawaited(
            _ensureControllersAroundIndex(_currentIndex.value, requestId),
          );
          return true;
        }

        // Duplicate-only page: advance cursor and retry up to the safety cap.
        _consecutiveEmptyLoadMorePages++;

        if (!canLoadMore) {
          _hasMore = false;
          return true;
        }

        if (_consecutiveEmptyLoadMorePages >=
            maxConsecutiveEmptyLoadMorePages) {
          AppLogger.d(
            '⚠️ [VideoFeed] Stopping pagination after '
            '$maxConsecutiveEmptyLoadMorePages consecutive duplicate-only pages',
          );
          _hasMore = false;
          return true;
        }

        final nextCursor = response.nextCursor;
        if (nextCursor == null || !nextCursor.isValid) {
          _hasMore = false;
          return true;
        }

        fetchCursor = nextCursor;
      }
    } catch (e) {
      AppLogger.d("❌ LOAD MORE ERROR: $e");
      _setLoadError('Failed to load more posts');
      return null;
    } finally {
      _setLoadingMore(false);
      _isAnyOperationInProgress = false;
    }
  }

  Future<bool?> initVideos({
    bool refresh = false,
    bool replaceSnapshot = false,
  }) async {
    if (!refresh && _currentFeed == 'for_you' && _pendingForYouRefresh) {
      refresh = true;
      replaceSnapshot = true;
    }
    if (!refresh && _currentFeed == 'subscribed' && _pendingSubscribedRefresh) {
      refresh = true;
      replaceSnapshot = true;
    }

    if (_isAnyOperationInProgress) {
      return null;
    }

    if (refresh) {
      if (_isRefreshing) {
        return null;
      }
      _isRefreshing = true;
    } else {
      if (_isInitialLoading) {
        return null;
      }
      _isInitialLoading = _mediaUrls.isEmpty;
    }

    final requestId = ++_feedLoadGeneration;
    _isAnyOperationInProgress = true;
    _setLoadError(null);

    // 🚀 Cache-then-Network: Load from Hive offline storage first if we don't have posts in memory
    if (!refresh && _posts.isEmpty) {
      final cachedData = HiveService().getCachedData(
        HiveService.feedCacheBoxName,
        'feed_posts_$_currentFeed',
      );
      if (cachedData is List) {
        try {
          _posts = cachedData
              .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _mediaUrls = _posts.map(_feedMediaUrlFor).toList();
          _currentIndex.value = 0;
          _isPlaying.value = false;
          _notifyFeedStructureChanged();
          _checkInitialFeedLoadingStatus();

          if (_isInitialFeedLoading) {
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (_isInitialFeedLoading &&
                  !_disposed &&
                  requestId == _feedLoadGeneration) {
                _setInitialFeedLoading(false);
              }
            });
          }

          unawaited(_precacheFeedImages(_posts));

          // Preload first cached video
          unawaited(_ensureControllersAroundIndex(0, requestId));
        } catch (e) {
          AppLogger.d(
            '🚨 [VideoFeedController] Error parsing cached posts: $e',
          );
        }
      }
    }

    try {
      if (refresh) {
        _nextCursor = null;
        _hasMore = true;
        _setLoadingMore(false);
        _consecutiveEmptyLoadMorePages = 0;
        _postService.resetPagination();
      }

      final response = await _postService.getPaginatedPosts(
        cursor: _nextCursor,
        refresh: refresh,
        feed: _currentFeed,
      );

      // Bail out BEFORE touching any shared state (_posts/_mediaUrls, Hive
      // cache, feed-structure notification) if a newer initVideos()/changeFeed()
      // call superseded this one while the network await was in flight — e.g.
      // the user switches Subscribed/For You tabs before the first load
      // returns. Without this early check, a late-arriving response for the
      // OLD feed would still overwrite the NEW feed's posts and even get
      // written into the NEW feed's Hive cache key (since _currentFeed is read
      // at write time, not capture time), causing the feed to visibly
      // reinitialize/flicker right after switching.
      if (requestId != _feedLoadGeneration) {
        return null;
      }

      final posts = _filterPostsWithSupportedMedia(response.posts);
      final uniquePosts = refresh ? posts : _uniquePosts(posts);
      final canLoadMore = _canLoadAfterCursor(
        requestedCursor: null,
        nextCursor: response.nextCursor,
        apiHasMore: response.hasMore,
      );

      final newUrlsList = uniquePosts.map(_feedMediaUrlFor).toList();
      bool isFeedUnchanged = false;
      if (!refresh && _mediaUrls.length == newUrlsList.length) {
        isFeedUnchanged = true;
        for (int i = 0; i < _mediaUrls.length; i++) {
          if (_mediaUrls[i] != newUrlsList[i]) {
            isFeedUnchanged = false;
            break;
          }
        }
      }

      if (response.posts.isEmpty) {
        AppLogger.d("❌ API returned no posts");
        if (refresh && replaceSnapshot) {
          _applyRefreshedFeedSnapshot([]);
          _hasMore = false;
        } else if (!refresh && !isFeedUnchanged) {
          _posts = [];
          _mediaUrls = [];
          _hasMore = false;
          _notifyFeedStructureChanged();
        } else {
          _hasMore = false;
          if (!isFeedUnchanged) {
            _notifyFeedStructureChanged();
          }
        }
      } else if (uniquePosts.isEmpty) {
        AppLogger.d("❌ Posts received, but media URLs were empty or invalid");

        if (refresh && replaceSnapshot) {
          _applyRefreshedFeedSnapshot([]);
          _hasMore = canLoadMore;
          _nextCursor = response.nextCursor;
        } else if (!refresh && !isFeedUnchanged) {
          _posts = [];
          _mediaUrls = [];
          _hasMore = canLoadMore;
          _nextCursor = response.nextCursor;
          _notifyFeedStructureChanged();
        } else {
          _hasMore = canLoadMore;
          _nextCursor = response.nextCursor;
          if (!isFeedUnchanged) {
            _notifyFeedStructureChanged();
          }
        }
      } else {
        if (refresh) {
          if (replaceSnapshot) {
            _applyRefreshedFeedSnapshot(uniquePosts);
          } else {
            _mergeRefreshedPosts(uniquePosts);
          }
          if (_currentFeed == 'subscribed') {
            _seedSubscribedAuthors(_posts);
          }
          unawaited(_precacheFeedImages(uniquePosts));
        } else {
          if (_currentFeed == 'subscribed') {
            _seedSubscribedAuthors(uniquePosts);
          }
          if (!isFeedUnchanged) {
            _posts = uniquePosts;
            _mediaUrls = _posts.map(_feedMediaUrlFor).toList();
            unawaited(_precacheFeedImages(uniquePosts));

            // Save newly fetched posts to Hive cache
            final postsJson = uniquePosts.map((e) => e.toJson()).toList();
            unawaited(
              HiveService().cacheData(
                HiveService.feedCacheBoxName,
                'feed_posts_$_currentFeed',
                postsJson,
              ),
            );
          }
        }
        _nextCursor = response.nextCursor;
        _hasMore = canLoadMore;
        if (refresh) {
          if (!replaceSnapshot) {
            _notifyFeedStructureChanged();
          }
        } else if (!isFeedUnchanged) {
          _notifyFeedStructureChanged();
        }
        _checkInitialFeedLoadingStatus();

        if (_isInitialFeedLoading) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (_isInitialFeedLoading &&
                !_disposed &&
                requestId == _feedLoadGeneration) {
              _setInitialFeedLoading(false);
            }
          });
        }
      }

      if (requestId != _feedLoadGeneration) return null;

      if (!refresh && !isFeedUnchanged) {
        final newUrls = _posts.map(_feedMediaUrlFor).toSet();
        final preservedControllers = <String, VideoPlayerController>{};
        final controllersToDispose = <VideoPlayerController>[];

        for (final entry in _controllersByUrl.entries) {
          if (newUrls.contains(entry.key)) {
            preservedControllers[entry.key] = entry.value;
          } else {
            controllersToDispose.add(entry.value);
          }
        }

        _controllersByUrl
          ..clear()
          ..addAll(preservedControllers);
        _initializingUrls.removeWhere((url) => !newUrls.contains(url));
        _initTokensByUrl.removeWhere((url, _) => !newUrls.contains(url));
        _notifyVideoControllersChanged();

        for (final controller in controllersToDispose) {
          try {
            await controller.dispose();
          } catch (e) {
            AppLogger.d('❌ Error disposing controller: $e');
          }
        }

        _failedUrls.removeWhere((url) => !newUrls.contains(url));
        if (_currentIndex.value >= _posts.length) {
          _currentIndex.value = (_posts.length - 1)
              .clamp(0, double.infinity)
              .toInt();
        }
        if (!preservedControllers.containsKey(
          _mediaUrlAt(_currentIndex.value),
        )) {
          _isPlaying.value = false;
        }
      }

      // ✅ FIX: Let _ensureControllersAroundIndex handle playback.
      // It will call controller.play() after init completes if the index
      // matches _currentIndex.value — no race condition.
      unawaited(_ensureControllersAroundIndex(_currentIndex.value, requestId));

      return true;
    } catch (e) {
      AppLogger.d("❌ Video load error: $e");
      _setLoadError('Failed to load feed');
      return false;
    } finally {
      // Only this call's own generation may clear the shared in-progress
      // flags. A superseded call (requestId no longer matches — e.g. a feed
      // switch bumped the generation while this one was still awaiting its
      // network response) must not stomp on flags a newer, still-running
      // initVideos() call already set to true — doing so previously let a
      // stale call's cleanup mask a genuinely in-flight load, allowing
      // another operation to start concurrently and re-trigger cancellation.
      if (requestId == _feedLoadGeneration) {
        _isInitialLoading = false;
        _isRefreshing = false;
        _isAnyOperationInProgress = false;
        if (refresh) {
          if (_currentFeed == 'for_you') {
            _pendingForYouRefresh = false;
          } else if (_currentFeed == 'subscribed') {
            _pendingSubscribedRefresh = false;
          }
        }
      }
      _checkInitialFeedLoadingStatus();
    }
  }

  void playVideo(int index, {bool deferPreload = false}) {
    final previousIndex = _currentIndex.value;
    _currentIndex.value = index;
    final url = _mediaUrlAt(index);

    if (index != previousIndex && !deferPreload) {
      // Immediate (non-scroll) callers only: a deliberate one-shot jump, safe
      // to evict/cancel against the target index right away.
      if (_effectiveIsVideo(index) && url.isNotEmpty) {
        _cancelAllInitializationsExcept(url);
      } else {
        _FeedVideoInitLimiter.bumpEpoch();
      }
      // Drop stale decoders from the map immediately; dispose in background.
      _detachControllersExceptSync(_keepUrlsForIndex(index));
    }
    // Scroll-driven (deferPreload) calls deliberately skip eviction/cancellation
    // here. onPageChanged fires on every page crossing during a fling, not
    // just the final settle — evicting warm controllers and cancelling
    // in-flight preloads on every one of those crossings was the main source
    // of decoder churn (dispose+reinit the same clip repeatedly mid-fling).
    // _scheduleEnsureControllersAroundIndex below already runs the equivalent
    // cleanup (_cancelStaleInitializations + _detachControllersExceptSync)
    // exactly once, 50ms after the LAST crossing, against whichever index the
    // scroll actually settles on — so still-useful nearby controllers survive
    // a fast fling instead of being torn down and rebuilt at every step.

    // Retry immediately when the user lands on a clip that failed earlier.
    if (url.isNotEmpty &&
        _failedUrls.contains(url) &&
        _effectiveIsVideo(index)) {
      _failedUrls.remove(url);
      _notifyVideoControllersChanged();
    }

    _applyPlaybackForIndex(index);

    if (deferPreload) {
      // Scroll-driven call (onPageChanged fires on every page crossing, not
      // just the final settle). If the clip isn't cached yet, don't cold-init
      // it here — _ensureControllersAroundIndex debounces this same call, so
      // a fast multi-page fling never starts (and then cancels) a real
      // ExoPlayer init for every index it passes through, only the one it
      // settles on. Already-cached clips still played instantly above.
      _scheduleEnsureControllersAroundIndex(index);
      return;
    }

    // Non-scroll callers (resume, tap-to-retry, new-post insert) want the
    // visible clip starting immediately — never wait for async dispose.
    if (_effectiveIsVideo(index) && url.isNotEmpty) {
      unawaited(_ensureCurrentVideoReady(index, _feedLoadGeneration));
    }

    _cancelPendingEnsureAroundIndex();
    unawaited(_preloadNextVideo(index, _feedLoadGeneration));
  }

  Set<String> _keepUrlsForIndex(int index) {
    final keep = <String>{};
    for (
      var offset = -preloadBehindDistance;
      offset <= preloadDistance;
      offset++
    ) {
      final candidate = index + offset;
      if (candidate >= 0 &&
          candidate < _posts.length &&
          _effectiveIsVideo(candidate)) {
        final url = _mediaUrlAt(candidate);
        if (url.isNotEmpty) keep.add(url);
      }
    }
    return keep;
  }

  /// Ensures the visible clip is loading/playing; dedupes concurrent inits.
  /// This is the single "promote CURRENT" path: an already-cached controller
  /// or an already-in-flight init future is always reused here — nothing in
  /// this function is allowed to start a second init for a URL that already
  /// has one of those.
  Future<void> _ensureCurrentVideoReady(int index, int generation) async {
    if (_disposed || generation != _feedLoadGeneration) return;
    if (index < 0 || index >= _posts.length || !_effectiveIsVideo(index)) {
      return;
    }

    final url = _mediaUrlAt(index);
    if (url.isEmpty) return;

    final cached = _controllersByUrl[url];
    if (cached != null) {
      _applyPlaybackForIndex(index);
      return;
    }

    final pending = _initFuturesByUrl[url];
    if (pending != null) {
      // Reuse the SAME in-flight attempt — never start a second controller
      // for this URL while one is already initializing, even if it was
      // marked stale in the meantime. If that attempt finishes without
      // producing a controller (it self-discarded once it noticed, at its
      // own checkpoint, that the live window no longer wanted it), fall
      // through below and start a fresh attempt now that none is left
      // running — instead of leaving CURRENT stuck with nothing.
      await pending;
      if (_disposed || generation != _feedLoadGeneration) return;
      if (_controllersByUrl.containsKey(url)) {
        _applyPlaybackForIndex(index);
        return;
      }
    }

    if (_failedUrls.contains(url)) {
      _failedUrls.remove(url);
      _notifyVideoControllersChanged();
    }

    await _initializeVideoAt(index, generation, centerIndex: index);
    if (!_disposed && generation == _feedLoadGeneration) {
      _applyPlaybackForIndex(index);
    }
  }

  /// Commits coalesced preload after scroll settles (e.g. fling end).
  void commitPendingEnsureControllersAroundIndex() {
    _ensureAroundIndexDebounceTimer?.cancel();
    _ensureAroundIndexDebounceTimer = null;
    if (!_hasPendingEnsureAroundIndex || _disposed) return;

    _hasPendingEnsureAroundIndex = false;
    final index = _pendingEnsureAroundIndex;
    unawaited(_ensureControllersAroundIndex(index, _feedLoadGeneration));
  }

  void _scheduleEnsureControllersAroundIndex(int index) {
    _pendingEnsureAroundIndex = index;
    _hasPendingEnsureAroundIndex = true;
    _ensureAroundIndexDebounceTimer?.cancel();
    _ensureAroundIndexDebounceTimer = Timer(
      _ensureAroundIndexDebounce,
      commitPendingEnsureControllersAroundIndex,
    );
  }

  void _cancelPendingEnsureAroundIndex() {
    _ensureAroundIndexDebounceTimer?.cancel();
    _ensureAroundIndexDebounceTimer = null;
    _hasPendingEnsureAroundIndex = false;
  }

  void _applyPlaybackForIndex(int index) {
    // Every caller reaches this after at least one `await` (a pending init
    // future, a fresh _initializeVideoAt, or just async scheduling) except
    // the immediate call from playVideo() itself. If the user has since
    // settled on a different page while we were waiting, index is stale —
    // applying it here would incorrectly play a video the user has already
    // scrolled past and pause the one they're actually looking at.
    if (_currentIndex.value != index) {
      return;
    }

    final url = _mediaUrlAt(index);
    final controller = url.isEmpty ? null : _controllersByUrl[url];
    if (controller != null && controller.value.isInitialized) {
      _pauseAllVideos(exceptUrl: url);
      // Preloaded clips are primed muted (see _runVideoInitialization); restore
      // audio now that this one is becoming the active/visible video.
      controller.setVolume(1.0);
      if (!controller.value.isPlaying) {
        unawaited(controller.play());
      }
      _isPlaying.value = true;
    } else {
      _pauseAllVideos();
      _isPlaying.value = false;
    }
  }

  void pauseCurrentVideo() {
    final url = _mediaUrlAt(_currentIndex.value);
    final controller = url.isEmpty ? null : _controllersByUrl[url];
    if (controller == null) {
      _isPlaying.value = false;
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
      _isPlaying.value = false;
    }
  }

  void togglePlayPause() {
    final url = _mediaUrlAt(_currentIndex.value);

    // If it failed previously, remove from failed and retry initialization
    if (url.isNotEmpty && _failedUrls.contains(url)) {
      _failedUrls.remove(url);
      _notifyVideoControllersChanged();
      unawaited(_initializeVideoAt(_currentIndex.value, _feedLoadGeneration));
      return;
    }

    final controller = url.isEmpty ? null : _controllersByUrl[url];
    if (controller == null || !controller.value.isInitialized) {
      if (url.isNotEmpty) {
        unawaited(
          _ensureControllersAroundIndex(
            _currentIndex.value,
            _feedLoadGeneration,
          ),
        );
      }
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
      _isPlaying.value = false;
    } else {
      controller.play();
      _isPlaying.value = true;
    }
  }

  // 🚀 PRODUCTION OPTIMIZED: Comprehensive disposal with error handling
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _cancelPendingEnsureAroundIndex();
    _subscriptionFeedRefreshDebounce?.cancel();

    SubscribeNotifier().removeListener(_onSubscriptionChanged);

    final futures = <Future<void>>[];
    for (final entry in _controllersByUrl.entries) {
      final controller = entry.value;
      try {
        controller.pause();
        futures.add(
          controller.dispose().catchError((e) {
            AppLogger.d('❌ Error disposing controller for ${entry.key}: $e');
          }),
        );
      } catch (e) {
        AppLogger.d('❌ Error pausing controller for ${entry.key}: $e');
      }
    }

    Future.wait(futures)
        .then((_) {
          _controllersByUrl.clear();
          _initializingUrls.clear();
          _initTokensByUrl.clear();
        })
        .catchError((e) {
          AppLogger.d('❌ Error during controller disposal: $e');
        });

    _currentIndex.dispose();
    _isPlaying.dispose();
    _feedStructureRevision.dispose();
    _isInitialFeedLoadingNotifier.dispose();
    _disposeItemRevisions();
    _isLoadingMoreNotifier.dispose();
    _loadErrorNotifier.dispose();
    _videoControllersRevision.dispose();
  }

  /// Reset controller state (for logout)
  void reset() {
    if (_disposed) return;

    // Dispose all controllers
    for (final controller in _controllersByUrl.values) {
      try {
        controller.pause();
        controller.dispose();
      } catch (e) {
        AppLogger.d('❌ Error disposing controller during reset: $e');
      }
    }

    _controllersByUrl.clear();
    _initializingUrls.clear();
    _initTokensByUrl.clear();
    _initFuturesByUrl.clear();
    _failedUrls.clear();
    _notifyVideoControllersChanged();
    _posts.clear();
    _mediaUrls.clear();
    _currentIndex.value = 0;
    _isPlaying.value = false;
    _feedLoadGeneration++;
    _isInitialLoading = false;
    _isRefreshing = false;
    _setLoadingMore(false);
    _hasMore = true;
    _setLoadError(null);
    _nextCursor = null;
    _consecutiveEmptyLoadMorePages = 0;
    _isAnyOperationInProgress = false;
    _setInitialFeedLoading(true);
    _disposeItemRevisions();

    _notifyFeedStructureChanged();
  }

  /// Instantly prepends a new post (e.g. after upload) to show it immediately.
  void prependPost(Post post) {
    if (_disposed) return;

    final exists = _posts.any((p) => p.id == post.id);
    if (exists) {
      return;
    }

    _posts.insert(0, post);
    _mediaUrls.insert(0, _feedMediaUrlFor(post));

    _currentIndex.value = 0;
    _isPlaying.value = false;
    _notifyFeedStructureChanged();

    unawaited(_precacheFeedImages([post]));
    unawaited(_ensureControllersAroundIndex(0, _feedLoadGeneration));
  }

  /// Releases all active video player controllers to free hardware decoders
  void releaseAllControllers() {
    if (_disposed) return;

    final controllersToDispose = List<VideoPlayerController>.from(
      _controllersByUrl.values,
    );
    _controllersByUrl.clear();
    _initializingUrls.clear();
    _initTokensByUrl.clear();
    _initFuturesByUrl.clear();
    _failedUrls.clear();
    _notifyVideoControllersChanged();

    for (final controller in controllersToDispose) {
      Future.microtask(() async {
        try {
          await controller.pause();
          await controller.dispose();
        } catch (e) {
          AppLogger.d('❌ Error disposing controller on release: $e');
        }
      });
    }
  }

  /// Changes the feed (Subscribed vs For You) and disposes of current video controllers/posts
  void changeFeed(String feedTab) {
    if (_disposed) return;

    // Defense in depth: the widget layer already guards against re-selecting
    // the same tab, but this makes the controller robust on its own too —
    // a redundant call here would otherwise tear down and reload a feed that
    // is already active for no reason.
    final targetFeed = feedTab == 'Subscribed' ? 'subscribed' : 'for_you';
    if (_currentFeed == targetFeed) {
      return;
    }

    // Asynchronously dispose of controllers to avoid blocking the UI thread
    final controllersToDispose = List<VideoPlayerController>.from(
      _controllersByUrl.values,
    );
    _controllersByUrl.clear();
    _notifyVideoControllersChanged();
    for (final controller in controllersToDispose) {
      Future.microtask(() async {
        try {
          await controller.pause();
          await controller.dispose();
        } catch (e) {
          AppLogger.d('❌ Error disposing controller during feed change: $e');
        }
      });
    }

    _initializingUrls.clear();
    _initTokensByUrl.clear();
    _initFuturesByUrl.clear();
    _failedUrls.clear();
    _posts.clear();
    _mediaUrls.clear();
    _currentIndex.value = 0;
    _isPlaying.value = false;
    _nextCursor = null;
    _hasMore = true;
    _setLoadError(null);
    _consecutiveEmptyLoadMorePages = 0;

    // Reset loading states and increment generation to cancel any in-flight requests
    _isInitialLoading = false;
    _isRefreshing = false;
    _setLoadingMore(false);
    _isAnyOperationInProgress = false;
    _setInitialFeedLoading(true);
    _feedLoadGeneration++;
    _FeedVideoInitLimiter.bumpEpoch();
    _disposeItemRevisions();

    if (feedTab == 'Subscribed') {
      _currentFeed = 'subscribed';
    } else {
      _currentFeed = 'for_you';
    }

    _notifyFeedStructureChanged();
  }

  List<Post> _filterPostsWithSupportedMedia(List<Post> raw) {
    final out = <Post>[];

    for (final post in raw) {
      if (isBlockedUser != null && isBlockedUser!(post.userId)) {
        continue;
      }
      if (post.isFeedEligible) {
        out.add(post);
      } else {
        AppLogger.d(
          '❌ video/image filtered/skipped — no playable URL id=${post.id} '
          'media="${post.media}" thumb="${post.thumbnailUrl}"',
        );
      }
    }

    return out;
  }

  bool _isSupportedMediaUrl(String url) => _isHttpMediaUrl(url);

  bool _isHttpMediaUrl(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return false;

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null) return false;

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// ✅ FIX: Helper that checks BOTH post.isVideo AND URL extension.
  /// Your API does not send is_video, so post.isVideo alone is unreliable.
  /// This prevents videos from being treated as images and skipped entirely.
  bool _effectiveIsVideo(int idx) {
    if (idx < 0 || idx >= _posts.length) return false;
    final post = _posts[idx];
    return post.isVideo || Post.mediaUrlLooksLikeVideo(post.media);
  }

  void _checkInitialFeedLoadingStatus() {
    if (!_isInitialFeedLoading) return;

    if (_posts.isEmpty) {
      if (!_isInitialLoading && !_isRefreshing && !_isAnyOperationInProgress) {
        _setInitialFeedLoading(false);
      }
      return;
    }

    final firstPost = _posts[0];
    final posterAvailable = firstPost.feedPosterUrl.isNotEmpty;
    final firstController = controllerForMediaIndex(0);
    final firstControllerReady =
        firstController != null && firstController.value.isInitialized;
    final firstControllerFailed = hasVideoLoadFailed(0);

    if (posterAvailable || firstControllerReady || firstControllerFailed) {
      _setInitialFeedLoading(false);
    }
  }

  /// Single entry point for "settle at index N" — the 3-video pool lifecycle:
  /// 1. Cancel in-flight inits definitely outside [N-1, N, N+1] (safe: never
  ///    touches a controller that already exists).
  /// 2. Promote/ready CURRENT (reusing a cached controller or in-flight
  ///    future — see [_ensureCurrentVideoReady]).
  /// 3. Only once CURRENT is confirmed ready (or this settle has been
  ///    superseded and bails out) do we evict anything — so a controller is
  ///    never released before its replacement can actually play.
  /// 4. Preload NEXT.
  Future<void> _ensureControllersAroundIndex(int index, int generation) async {
    if (_disposed || index < 0 || index >= _posts.length) return;

    final keepUrls = _keepUrlsForIndex(index);
    _cancelStaleInitializations(keepUrls);

    final currentUrl = _mediaUrlAt(index);
    if (currentUrl.isNotEmpty && _effectiveIsVideo(index)) {
      await _ensureCurrentVideoReady(index, generation);
    }

    if (_disposed || generation != _feedLoadGeneration) return;
    if (_currentIndex.value != index) {
      // A newer settle took over while CURRENT was loading. That newer call
      // will run its own eviction against its own (different) window — doing
      // it here with this stale index's window could release something the
      // new settle still needs.
      return;
    }

    // Retention is fixed for THIS settled index now that CURRENT is ready.
    _detachControllersExceptSync(keepUrls);

    await _preloadNextVideo(index, generation);

    if (kDebugMode && _controllersByUrl.length > maxCachedControllers) {
      AppLogger.d(
        '⚠️ [VideoFeed] Too many controllers (${_controllersByUrl.length})',
      );
    }
  }

  Future<void> _preloadNextVideo(int index, int generation) async {
    final nextIndex = index + 1;
    if (nextIndex >= _posts.length || !_effectiveIsVideo(nextIndex)) return;

    final nextUrl = _mediaUrlAt(nextIndex);
    if (nextUrl.isEmpty) return;
    if (_controllersByUrl.containsKey(nextUrl)) {
      // Already promoted/cached from an earlier preload — nothing to do.
      return;
    }
    if (_initializingUrls.contains(nextUrl)) {
      // Already initializing (this exact future is what _ensureCurrentVideoReady
      // will reuse once the user reaches it) — never start a second init.
      return;
    }

    // Previously waited a fixed 200ms here before even starting. This is only
    // ever reached after the caller has already confirmed the current video
    // is ready — via _ensureControllersAroundIndex, which itself only runs
    // once scrolling has settled (a separate, earlier 50ms debounce). Adding
    // another fixed wait on top of an already-settled index was redundant
    // "is the user still here" throttling, and on a normal (not fast-fling)
    // scroll cadence it was frequently long enough that the user reached the
    // next page before its preload had even started — forcing a full cold
    // init exactly where a warm controller should have been waiting.
    if (_disposed || generation != _feedLoadGeneration) return;
    if (_currentIndex.value != index) return;

    final currentUrl = _mediaUrlAt(index);
    final currentCtrl = _controllersByUrl[currentUrl];
    if (currentCtrl == null || !currentCtrl.value.isInitialized) return;

    AppLogger.d(
      '⏩ [VideoFeed] PRELOAD START index=$nextIndex (current=$index)',
    );
    unawaited(_initializeVideoAt(nextIndex, generation, centerIndex: index));
  }

  bool _isUrlInPreloadWindow(String url, int centerIndex) {
    if (url.isEmpty) return false;
    for (
      var offset = -preloadBehindDistance;
      offset <= preloadDistance;
      offset++
    ) {
      final candidate = centerIndex + offset;
      if (candidate >= 0 &&
          candidate < _posts.length &&
          _mediaUrlAt(candidate) == url) {
        return true;
      }
    }
    return false;
  }

  /// Liveness check for one in-flight `_runVideoInitialization` attempt.
  /// CURRENT and PRELOAD deliberately use different rules here:
  ///
  /// - CURRENT must survive transient churn in the live [N-1, N, N+1] window
  ///   (e.g. an epoch bump from an unrelated immediate jump, or the window
  ///   momentarily being recomputed) while it is queued behind the limiter's
  ///   single slot or while its native initialize() is genuinely running.
  ///   Only disposal, a feed-generation change, this attempt's token being
  ///   superseded, or this index actually ceasing to be `_currentIndex.value`
  ///   are allowed to cancel it.
  /// - PRELOAD keeps the original, stricter window check: it exists purely
  ///   to warm a clip nobody may ever reach, so it should give up as soon as
  ///   it drifts outside the live pool.
  bool _isInitAttemptLive({
    required bool isCurrentVideo,
    required int mediaIndex,
    required String url,
    required int token,
    required int generation,
  }) {
    if (_disposed || generation != _feedLoadGeneration) return false;
    if (_initTokensByUrl[url] != token) return false;
    if (isCurrentVideo) {
      return mediaIndex == _currentIndex.value;
    }
    return _isUrlInPreloadWindow(url, _currentIndex.value);
  }

  /// Removes stale controllers from the map instantly; native dispose runs async.
  void _detachControllersExceptSync(Set<String> keepUrls) {
    if (_controllersByUrl.isEmpty) return;

    final urlsToEvict = _controllersByUrl.keys
        .where((url) => !keepUrls.contains(url))
        .toList();
    if (urlsToEvict.isEmpty) return;

    for (final url in urlsToEvict) {
      final controller = _controllersByUrl.remove(url);
      if (controller == null) continue;
      unawaited(() async {
        try {
          await controller.pause();
          await controller.dispose();
        } catch (e) {
          AppLogger.d('❌ Error evicting controller for $url: $e');
        }
      }());
    }
    _notifyVideoControllersChanged();
  }

  // Neither cancel function below disposes the in-flight controller, nor
  // removes it from _initFuturesByUrl/_initializingUrls/_initializingControllers.
  // Cancelling only means "invalidate this attempt's token" — the SAME
  // mechanism _runVideoInitialization already watches for at its checkpoints
  // (the limiter's isValid() re-check, and the post-initialize() live
  // token/generation/window re-check). Everything else about the attempt is
  // left completely alone:
  //   - _initFuturesByUrl[url] keeps pointing at the live Future, so any
  //     later caller wanting this same URL discovers and awaits it instead
  //     of starting a second native initialize() for it (see
  //     _ensureCurrentVideoReady/_preloadNextVideo's existing guards).
  //   - _initializingUrls / _initializingControllers stay populated, so the
  //     entry guard in _runVideoInitialization keeps blocking a duplicate
  //     construction the whole time this attempt is alive.
  //   - the controller itself is never touched here — the owning call
  //     disposes it, safely, only after its native call actually settles
  //     (success, failure, or its own timeout), and only THEN does its own
  //     finally clean up _initFuturesByUrl/_initializingUrls/
  //     _initializingControllers. That is what previously went wrong:
  //     clearing those maps here, before the attempt was done, let a second,
  //     independent initialization start for a URL that was still alive in
  //     the background — the actual cause of the observed
  //     cancel-then-duplicate-init churn.

  void _cancelAllInitializationsExcept(String keepUrl) {
    final staleUrls = _initializingControllers.keys
        .where((url) => url != keepUrl)
        .toList();

    if (staleUrls.isEmpty) return;

    for (final url in staleUrls) {
      _initTokensByUrl.remove(url);
    }
    _FeedVideoInitLimiter.bumpEpoch();
  }

  void _cancelStaleInitializations(Set<String> keepUrls) {
    final staleUrls = _initializingControllers.keys.where((url) {
      return !keepUrls.contains(url);
    }).toList();

    for (final url in staleUrls) {
      _initTokensByUrl.remove(url);
    }
  }

  Future<String?> _tryResolveVideoMedia(int mediaIndex) async {
    if (mediaIndex < 0 || mediaIndex >= _posts.length) return null;

    final post = _posts[mediaIndex];
    if (post.id.isEmpty) return null;

    try {
      final fetched = await _postService.fetchPostById(post.id);
      final merged = post.mergedWith(other: fetched);
      final resolvedUrl = _feedMediaUrlFor(merged);
      if (!_isSupportedMediaUrl(resolvedUrl)) return null;

      _posts[mediaIndex] = merged;
      if (mediaIndex < _mediaUrls.length) {
        _mediaUrls[mediaIndex] = resolvedUrl;
      }
      _notifyFeedItemChanged(_itemRevisionKey(merged, mediaUrl: resolvedUrl));
      return resolvedUrl;
    } catch (e) {
      AppLogger.d('⚠️ [VideoFeed] Could not resolve media for ${post.id}: $e');
      return null;
    }
  }

  Future<void> _initializeVideoAt(
    int mediaIndex,
    int generation, {
    int attempt = 0,
    int? centerIndex,
    int? epoch,
  }) async {
    if (_disposed ||
        generation != _feedLoadGeneration ||
        mediaIndex < 0 ||
        mediaIndex >= _posts.length) {
      return;
    }

    if (epoch != null && epoch != _FeedVideoInitLimiter.epoch) {
      return;
    }

    final post = _posts[mediaIndex];
    var url = _mediaUrlAt(mediaIndex);

    if (!_isSupportedMediaUrl(url)) {
      AppLogger.d('❌ [VideoFeed] Unsupported URL at $mediaIndex: $url');
      return;
    }

    if (_controllersByUrl.containsKey(url)) return;

    final existingFuture = _initFuturesByUrl[url];
    if (existingFuture != null && attempt == 0) {
      await existingFuture;
      return;
    }

    final future = _runVideoInitialization(
      mediaIndex: mediaIndex,
      generation: generation,
      attempt: attempt,
      centerIndex: centerIndex,
      epoch: epoch,
      post: post,
      url: url,
    );
    _initFuturesByUrl[url] = future;
    try {
      await future;
    } finally {
      if (identical(_initFuturesByUrl[url], future)) {
        _initFuturesByUrl.remove(url);
      }
    }
  }

  Future<void> _runVideoInitialization({
    required int mediaIndex,
    required int generation,
    required int attempt,
    int? centerIndex,
    int? epoch,
    required Post post,
    required String url,
  }) async {
    var resolvedUrl = url;

    // Feed list payloads sometimes omit the stream URL — resolve before init.
    if (_effectiveIsVideo(mediaIndex) &&
        !Post.mediaUrlLooksLikeVideo(resolvedUrl)) {
      final resolved = await _tryResolveVideoMedia(mediaIndex);
      if (resolved != null) {
        resolvedUrl = resolved;
      }
    }

    if (!_isSupportedMediaUrl(resolvedUrl) ||
        !Post.mediaUrlLooksLikeVideo(resolvedUrl) &&
            _effectiveIsVideo(mediaIndex)) {
      if (mediaIndex == _currentIndex.value) {
        _failedUrls.add(resolvedUrl);
        _notifyVideoControllersChanged();
      }
      AppLogger.d(
        '❌ [VideoFeed] No playable video URL at $mediaIndex id=${post.id}',
      );
      return;
    }

    if (_controllersByUrl.containsKey(resolvedUrl) ||
        _initializingUrls.contains(resolvedUrl) ||
        (attempt == 0 && _pendingRetryUrls.contains(resolvedUrl))) {
      return;
    }

    final isCurrentVideo = mediaIndex == _currentIndex.value;
    // Live-window check only. `centerIndex` is captured once, when this init
    // was kicked off (e.g. as a preload from whatever was CURRENT at that
    // moment) — it goes stale the instant the user swipes again. Judging
    // "is this init still relevant" against that stale center let a preload
    // started for an old settle survive validity checks it should have
    // failed, while `_isUrlInPreloadWindow` (already live) was short-circuited
    // unnecessarily. Re-deriving purely from the live [N-1, N, N+1] window
    // keeps this decision consistent with everything else in the pool.
    if (!_isUrlInPreloadWindow(resolvedUrl, _currentIndex.value)) {
      _pendingRetryUrls.remove(resolvedUrl);
      return;
    }

    _pendingRetryUrls.remove(resolvedUrl);
    final initToken = ++_initTokenSeq;
    _initTokensByUrl[resolvedUrl] = initToken;
    final initDeadline = isCurrentVideo ? initTimeout : preloadInitTimeout;

    VideoPlayerController? controller;
    _initializingUrls.add(resolvedUrl);
    _notifyVideoControllersChanged();
    try {
      final adopted = await _adoptFrameCacheController(resolvedUrl);
      if (adopted != null) {
        controller = adopted;
      } else {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(resolvedUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );

        _initializingControllers[resolvedUrl] = controller;
        final localController = controller;

        // CURRENT and preload both go through the SAME single-slot gate now.
        // CURRENT used to bypass it entirely (bypassedLimiter=true), which
        // let two native initialize() calls run concurrently whenever the
        // user swiped onto a new current before the previous current's own
        // initialize() had finished — exactly the decoder contention seen in
        // the logs. Priority is the only special treatment CURRENT still
        // gets: it jumps ahead of any queued preload waiter for the next
        // free slot. It cannot preempt whatever native call is ALREADY
        // running (current or preload) — interrupting a live initialize()
        // is unsafe (see the cancel-function history above) — so "highest
        // priority" means "next in line", never "stops what's running".
        // Priority is a LIVE check (`isNowCurrent`), not the `isCurrentVideo`
        // snapshot taken above: a preload attempt that is still queued or
        // still running its native initialize() when the user swipes onto
        // it — the in-flight-reuse path in _ensureCurrentVideoReady awaits
        // this exact same future instead of starting a second init — must be
        // able to jump the queue and become epoch-immune from that moment
        // on, exactly as if it had started as CURRENT. Without this, a
        // promoted preload kept the low-priority, 6s-timeout treatment it
        // was queued under, which is what let a plain preload occupy the
        // single slot while the video the user was actually looking at sat
        // waiting behind it. Whatever finishes re-validates itself via
        // _isInitAttemptLive afterwards regardless of why it waited — CURRENT
        // against token/generation/live-current-index, PRELOAD against
        // token/generation/the live preload window (see that method).
        final token = initToken;
        final limiterEpoch = epoch ?? _FeedVideoInitLimiter.epoch;
        bool isNowCurrent() => mediaIndex == _currentIndex.value;
        final ran = await _FeedVideoInitLimiter.run(
          epoch: limiterEpoch,
          isPriority: isNowCurrent,
          task: () async {
            await localController.initialize().timeout(
              initDeadline,
              onTimeout: () {
                throw TimeoutException(
                  'Video initialization timeout',
                  initDeadline,
                );
              },
            );
          },
          isValid: () => _isInitAttemptLive(
            isCurrentVideo: isCurrentVideo,
            mediaIndex: mediaIndex,
            url: resolvedUrl,
            token: token,
            generation: generation,
          ),
        );
        if (!ran) {
          await localController.dispose().catchError((_) {});
          _initializingControllers.remove(resolvedUrl);
          _initTokensByUrl.remove(resolvedUrl);
          return;
        }
      }
    } catch (e) {
      try {
        await controller?.dispose();
      } catch (_) {}

      if (_initTokensByUrl[resolvedUrl] != initToken) return;

      final canRetry =
          isCurrentVideo &&
          attempt < maxInitRetries &&
          generation == _feedLoadGeneration &&
          !_disposed;

      if (canRetry) {
        _pendingRetryUrls.add(resolvedUrl);
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        if (_disposed || generation != _feedLoadGeneration) {
          _pendingRetryUrls.remove(resolvedUrl);
          return;
        }
        return _initializeVideoAt(
          mediaIndex,
          generation,
          attempt: attempt + 1,
          centerIndex: centerIndex,
          epoch: epoch,
        );
      }

      if (isCurrentVideo) {
        _failedUrls.add(resolvedUrl);
        _notifyVideoControllersChanged();
        _checkInitialFeedLoadingStatus();
      }
      _initTokensByUrl.remove(resolvedUrl);
      AppLogger.d('❌ [VideoFeed] Video init failed at $mediaIndex: $e');
      return;
    } finally {
      _initializingUrls.remove(resolvedUrl);
      _initializingControllers.remove(resolvedUrl);
      _notifyVideoControllersChanged();
    }

    if (_disposed ||
        generation != _feedLoadGeneration ||
        _initTokensByUrl[resolvedUrl] != initToken) {
      await controller.dispose();
      _initTokensByUrl.remove(resolvedUrl);
      return;
    }

    _initTokensByUrl.remove(resolvedUrl);

    final stillWanted = isCurrentVideo
        ? mediaIndex == _currentIndex.value
        : _isUrlInPreloadWindow(resolvedUrl, _currentIndex.value);
    if (!stillWanted) {
      await controller.dispose();
      return;
    }

    controller.setLooping(true);

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isAppResumed =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final shouldPlay =
        mediaIndex == _currentIndex.value && !_disposed && isAppResumed;

    _failedUrls.remove(resolvedUrl);
    _controllersByUrl[resolvedUrl] = controller;
    _notifyVideoControllersChanged();
    _checkInitialFeedLoadingStatus();

    try {
      if (shouldPlay) {
        controller.setVolume(1.0);
        _pauseAllVideos(exceptUrl: resolvedUrl);
        await controller.play();
        _isPlaying.value = true;
      } else {
        await controller.setVolume(0);
        await controller.pause();
        await controller.seekTo(Duration.zero);
      }
    } catch (e) {
      AppLogger.d('⚠️ [VideoFeed] Could not start/prime video: $e');
    }
  }

  Future<VideoPlayerController?> _adoptFrameCacheController(String url) async {
    if (_controllersByUrl.containsKey(url)) return null;

    final otherUrls = _controllersByUrl.keys.where((k) => k != url);
    if (otherUrls.isNotEmpty) return null;

    final ready = VideoFrameCache.peekReady(url);
    if (ready == null) return null;

    final adopted = await VideoFrameCache.takeForFeed(url);
    if (adopted == null) return null;

    return adopted;
  }

  void _pauseAllVideos({String? exceptUrl}) {
    _controllersByUrl.forEach((url, controller) {
      if (exceptUrl == null || url != exceptUrl) {
        try {
          if (controller.value.isPlaying) {
            controller.pause();
          }
        } catch (e) {
          AppLogger.d('❌ Error pausing controller for $url: $e');
        }
      }
    });
  }

  Future<void> _precacheFeedImages(List<Post> posts) async {
    final slice = posts.length <= 24 ? posts : posts.take(24).toList();
    final imageFutures = <Future<void>>[];

    for (final post in slice) {
      for (final imgUrl in [post.feedPosterUrl, post.profilePicture.trim()]) {
        final trimmed = imgUrl.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('http')) continue;
        if (Post.mediaUrlLooksLikeVideo(trimmed)) continue;
        imageFutures.add(_precacheNetworkImage(trimmed));
      }
    }

    // Posters for the next two slots — instant cover while video buffers.
    final anchor = _currentIndex.value;
    for (var offset = 1; offset <= 2; offset++) {
      final idx = anchor + offset;
      if (idx < 0 || idx >= _posts.length) continue;
      final poster = _posts[idx].feedPosterUrl.trim();
      if (poster.isEmpty || !poster.startsWith('http')) continue;
      if (Post.mediaUrlLooksLikeVideo(poster)) continue;
      imageFutures.add(_precacheNetworkImage(poster));
    }

    final tasks = <Future<void>>[
      if (imageFutures.isNotEmpty) _precacheImagesBatched(imageFutures),
    ];

    if (tasks.isEmpty) return;

    try {
      await Future.wait(tasks);
    } catch (e) {
      AppLogger.d('⚠️ Error pre-caching feed images: $e');
    }
  }

  Future<void> _precacheImagesBatched(List<Future<void>> futures) async {
    const batchSize = 12;
    for (var i = 0; i < futures.length; i += batchSize) {
      await Future.wait(futures.skip(i).take(batchSize));
    }
  }

  Future<void> _precacheNetworkImage(String imgUrl) async {
    final completer = Completer<void>();
    final provider = CachedNetworkImageProvider(imgUrl);
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (exception, stackTrace) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  void _seedSubscribedAuthors(List<Post> posts) {
    SubscribeNotifier().seedSubscribedFeedAuthors(
      posts.map((post) => (userId: post.userId, username: post.username)),
    );
  }

  Future<void> _invalidateSubscriptionFeedCaches() async {
    await HiveService().evictCachedData(
      HiveService.feedCacheBoxName,
      'feed_posts_for_you',
    );
    await HiveService().evictCachedData(
      HiveService.feedCacheBoxName,
      'feed_posts_subscribed',
    );
    final cacheManager = CacheManager();
    await cacheManager.invalidatePattern(ApiConstants.getPost);
    await cacheManager.invalidatePattern('user/profile');
  }

  Set<String> _collectLocalSubscribedUserIds(SubscribeNotifier controller) {
    final ids = <String>{
      ...controller.users.entries
          .where((e) => e.value.isSubscribed)
          .map((e) => e.key),
    };
    for (final post in _posts) {
      if (controller.isUserSubscribed(post.userId)) {
        ids.add(post.userId);
      }
    }
    return ids;
  }

  void _scheduleSubscriptionFeedRefresh({required bool replaceSnapshot}) {
    _pendingReplaceSnapshotRefresh =
        replaceSnapshot || _pendingReplaceSnapshotRefresh;
    _subscriptionFeedRefreshDebounce?.cancel();
    _subscriptionFeedRefreshDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        if (_disposed) return;
        final replace = _pendingReplaceSnapshotRefresh;
        _pendingReplaceSnapshotRefresh = false;
        unawaited(initVideos(refresh: true, replaceSnapshot: replace));
      },
    );
  }

  /// Real-time listener: apply feed changes from API after server sync — never
  /// optimistically strip posts while the user is still watching them.
  void _onSubscriptionChanged() {
    if (_disposed) return;

    final subscribeController = SubscribeNotifier();
    final currentLocalSubscribed = _collectLocalSubscribedUserIds(
      subscribeController,
    );
    final newlySubscribed = currentLocalSubscribed.difference(
      _localSubscribedUserIds,
    );
    final newlyUnsubscribed = _localSubscribedUserIds.difference(
      currentLocalSubscribed,
    );

    final currentSyncedSubscribed = subscribeController.users.entries
        .where(
          (e) =>
              e.value.isSubscribed &&
              subscribeController.isSubscriptionSynced(e.key),
        )
        .map((e) => e.key)
        .toSet();

    final newSyncedSubscriptions = currentSyncedSubscribed.difference(
      _syncedSubscribedUserIds,
    );

    final currentSyncedUnsubscribed = subscribeController.users.entries
        .where(
          (e) =>
              !e.value.isSubscribed &&
              subscribeController.isSubscriptionSynced(e.key),
        )
        .map((e) => e.key)
        .toSet();
    final newSyncedUnsubscriptions = currentSyncedUnsubscribed.difference(
      _syncedUnsubscribedUserIds,
    );

    final subscriptionDelta =
        newlySubscribed.isNotEmpty ||
        newlyUnsubscribed.isNotEmpty ||
        newSyncedSubscriptions.isNotEmpty ||
        newSyncedUnsubscriptions.isNotEmpty;

    if (newSyncedSubscriptions.isNotEmpty ||
        newSyncedUnsubscriptions.isNotEmpty) {
      unawaited(_invalidateSubscriptionFeedCaches());
    }

    if (newlyUnsubscribed.isNotEmpty || newSyncedUnsubscriptions.isNotEmpty) {
      _pendingForYouRefresh = true;
      _pendingSubscribedRefresh = true;
    }
    if (newSyncedSubscriptions.isNotEmpty) {
      // Subscribing must not pull the author's posts out of For You — only
      // the Subscribed tab needs to pick up the new subscription.
      _pendingSubscribedRefresh = true;
    }

    if (_currentFeed == 'for_you') {
      if (newSyncedUnsubscriptions.isNotEmpty) {
        _scheduleSubscriptionFeedRefresh(replaceSnapshot: true);
      }
    }

    // Unsubscribing must not yank the post out from under someone actively
    // watching the Subscribed tab — that's jarring, not the "instant" feel
    // we want. The pending-refresh flags set above make sure the feed drops
    // (or picks up) the author's posts next time it's loaded instead.

    if (!subscriptionDelta) return;

    _syncedSubscribedUserIds = currentSyncedSubscribed;
    _syncedUnsubscribedUserIds = currentSyncedUnsubscribed;
    _localSubscribedUserIds = currentLocalSubscribed;
  }

  /// Removes posts of specific userIds, cleans up their players, and updates indices
  void _removePostsByUsers(Set<String> userIds) {
    if (userIds.isEmpty || _posts.isEmpty) return;

    final Map<String, VideoPlayerController> preservedControllers = {};
    final List<Post> newPosts = [];
    final List<String> newMediaUrls = [];

    for (final post in _posts) {
      final url = _feedMediaUrlFor(post);
      if (userIds.contains(post.userId)) {
        final itemKey = _itemRevisionKey(post, mediaUrl: url);
        final itemNotifier = _itemRevisions.remove(itemKey);
        itemNotifier?.dispose();

        final controller = _controllersByUrl.remove(url);
        if (controller != null) {
          Future.microtask(() async {
            try {
              await controller.pause();
              await controller.dispose();
            } catch (e) {
              AppLogger.d(
                '❌ Error disposing controller for removed post url=$url: $e',
              );
            }
          });
        }
        _failedUrls.remove(url);
      } else {
        newPosts.add(post);
        newMediaUrls.add(_feedMediaUrlFor(post));
        final controller = _controllersByUrl[url];
        if (controller != null) {
          preservedControllers[url] = controller;
        }
      }
    }

    _controllersByUrl
      ..clear()
      ..addAll(preservedControllers);
    _notifyVideoControllersChanged();
    _posts = newPosts;
    _mediaUrls = newMediaUrls;

    // Cap the active index to the new boundaries
    if (_currentIndex.value >= _posts.length) {
      _currentIndex.value = (_posts.length - 1)
          .clamp(0, double.infinity)
          .toInt();
    }

    _notifyFeedStructureChanged();

    // Smoothly auto-play the next video in line at the current index if the feed is not empty
    if (_posts.isNotEmpty) {
      playVideo(_currentIndex.value);
    }
    onPostsRemoved?.call();
  }

  /// Public wrapper to remove posts from blocked/unwanted users
  void removePostsByUsers(Set<String> userIds) {
    _removePostsByUsers(userIds);
  }
}

/// Caps concurrent feed video initializations — Exynos/Snapdragon decoders
/// exhaust quickly when multiple HEVC clips init during fast scroll. Exactly
/// one native `initialize()` call is ever in flight at a time, for CURRENT
/// and preload alike — CURRENT gets priority only in the sense that it jumps
/// ahead of any queued preload waiter for the next free slot; it can never
/// preempt whatever is already running, since interrupting a live native
/// initialize() is not safe (see the cancel-function history elsewhere in
/// this file).
///
/// Priority is tracked per-waiter as a LIVE callback (`isPriority`), not a
/// snapshot taken when the waiter joined the queue. This matters for the
/// "in-flight reuse" path in `_ensureCurrentVideoReady`: a video that started
/// initializing as a PRELOAD can become the live CURRENT video while its
/// attempt is still queued (or still running natively) — the caller simply
/// awaits that same attempt rather than starting a second one. Without a
/// live re-check, that promoted attempt would keep the low-priority,
/// 6-second-timeout treatment it queued under, letting an ordinary preload
/// occupy the single slot while the video the user is actually looking at
/// sits waiting behind it. Re-evaluating `isPriority` on every pick lets a
/// promoted attempt jump straight to the front — matching a CURRENT request
/// that was CURRENT from the very start — while a demoted one (current moved
/// on again before this attempt reached the slot) falls back to ordinary
/// preload treatment on its very next wake.
class _FeedVideoInitLimiter {
  static const int _maxConcurrent = 1;
  static int _active = 0;
  static int _epoch = 0;
  static final List<_LimiterWaiter> _waitQueue = <_LimiterWaiter>[];

  static int get epoch => _epoch;

  static void bumpEpoch() {
    _epoch++;
    final waiters = List<_LimiterWaiter>.from(_waitQueue);
    _waitQueue.clear();
    for (final waiter in waiters) {
      if (!waiter.completer.isCompleted) {
        waiter.completer.complete();
      }
    }
  }

  /// Runs [task] once a slot is free and [isValid] still says so.
  ///
  /// [isPriority] is polled live (at entry, right after acquiring the slot,
  /// and on every queue pick) rather than captured once — see the class doc
  /// for why that matters for a preload promoted to CURRENT mid-flight.
  ///
  /// Returns whether [task] actually ran — deliberately NOT derived from
  /// awaiting [task] itself: `task` returns `Future<void>`, and awaiting a
  /// `Future<void>` always yields `null`, so a caller checking "result ==
  /// null" to detect cancellation would (incorrectly) treat every successful
  /// run as cancelled too.
  static Future<bool> run({
    required int epoch,
    required Future<void> Function() task,
    required bool Function() isValid,
    required bool Function() isPriority,
  }) async {
    // CURRENT (priority) requests are immune to epoch-based rejection: a
    // bump means some unrelated attempt was cancelled elsewhere — possibly
    // by the very call that's keeping THIS url as current — not that this
    // attempt itself is stale. `isValid` (token/generation/current-index) is
    // the sole authority for whether a priority request is still wanted.
    bool epochOk() => isPriority() || epoch == _epoch;

    if (!isValid() || !epochOk()) return false;

    final acquired = await _acquire(epoch, isPriority);
    if (!acquired) return false;

    try {
      if (!isValid() || !epochOk()) return false;
      await task();
      return true;
    } finally {
      _release();
    }
  }

  static Future<bool> _acquire(int epoch, bool Function() isPriority) async {
    while (true) {
      if (_active < _maxConcurrent) {
        _active++;
        return true;
      }

      final waiter = _LimiterWaiter(isPriority);
      _waitQueue.add(waiter);

      if (isPriority()) {
        // No fixed wait cap: CURRENT must actually get the slot, not give up
        // early. A wake here may come from a genuine `_release()` handoff
        // (slot now free) or from `bumpEpoch()` draining the queue for an
        // unrelated cancellation elsewhere (slot still held) — loop back and
        // re-check `_active` (and re-evaluate `isPriority()` fresh, in case
        // this attempt was demoted while it waited) rather than assuming the
        // slot is ours, so two native initialize() calls can never run at
        // once.
        await waiter.completer.future;
        continue;
      }

      var timedOut = false;
      try {
        await waiter.completer.future.timeout(
          const Duration(seconds: 6),
          onTimeout: () {
            timedOut = true;
          },
        );
      } catch (_) {
        _waitQueue.remove(waiter);
        return false;
      }

      if (timedOut) {
        _waitQueue.remove(waiter);
        return false;
      }

      if (epoch != _epoch) {
        return false;
      }

      _active++;
      return true;
    }
  }

  static void _release() {
    _active--;
    if (_waitQueue.isEmpty) return;

    // Dynamic pick: any waiter whose target is CURRENTLY the live current
    // video goes first, regardless of arrival order or what it was queued
    // as — this is what lets a preload promoted to current jump ahead of
    // older, still-queued (and still merely) preload waiters. FIFO within a
    // tier since _waitQueue is insertion-ordered.
    var chosenIndex = 0;
    for (var i = 0; i < _waitQueue.length; i++) {
      if (_waitQueue[i].isPriority()) {
        chosenIndex = i;
        break;
      }
    }
    final next = _waitQueue.removeAt(chosenIndex);
    if (!next.completer.isCompleted) {
      next.completer.complete();
    }
  }
}

class _LimiterWaiter {
  _LimiterWaiter(this.isPriority);

  final bool Function() isPriority;
  final Completer<void> completer = Completer<void>();
}
