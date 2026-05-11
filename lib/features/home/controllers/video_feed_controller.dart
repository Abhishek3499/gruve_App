import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:video_player/video_player.dart';

class VideoFeedController {
  bool _disposed = false;
  int _feedLoadGeneration = 0;

  List<String> _mediaUrls = [];
  List<String> get mediaUrls => _mediaUrls;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  final PostService _postService = PostService();
  final Map<int, VideoPlayerController> _controllers =
      <int, VideoPlayerController>{};
  final Set<int> _failedVideoIndexes = <int>{};
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<int> _feedRevision = ValueNotifier(0);

  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _loadError;
  CursorModel? _nextCursor;

  // Request deduplication
  int _lastRefreshRequestId = 0;
  int _lastLoadMoreRequestId = 0;

  // Separate loading states for better UX
  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;

  // ADDED: Missing getters that were causing compile errors
  ValueNotifier<int> get currentIndex => _currentIndex;
  bool get hasMore => _hasMore;
  String? get loadError => _loadError;
  ValueNotifier<int> get feedRevision => _feedRevision;
  int get gen => _feedLoadGeneration;

  // ADDED: Missing method that was causing compile errors
  void _notifyFeedChanged() {
    _feedRevision.value++;
  }

  /// Merges refreshed posts at the top, avoiding duplicates and preserving scroll position
  void _mergeRefreshedPosts(List<Post> newPosts) {
    final existingIds = _posts.map((post) => post.id).toSet();

    // Filter out posts that already exist
    final uniqueNewPosts = newPosts
        .where((post) => !existingIds.contains(post.id))
        .toList();

    if (uniqueNewPosts.isEmpty) {
      if (kDebugMode) {
        debugPrint('No new posts to merge - all posts already exist');
      }
      return;
    }

    // Insert new posts at the beginning
    _posts.insertAll(0, uniqueNewPosts);
    _mediaUrls.insertAll(0, uniqueNewPosts.map((e) => e.media).toList());

    if (kDebugMode) {
      debugPrint('Merged ${uniqueNewPosts.length} new posts at the top');
      debugPrint('Total posts after merge: ${_posts.length}');
    }

    // Adjust current index to maintain scroll position relative to old content
    if (_currentIndex.value > 0) {
      _currentIndex.value += uniqueNewPosts.length;
    }
  }

  VideoPlayerController? controllerForMediaIndex(int mediaIndex) {
    return _controllers[mediaIndex];
  }

  bool hasVideoLoadFailed(int mediaIndex) {
    return _failedVideoIndexes.contains(mediaIndex);
  }

  Future<bool?> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _isRefreshing) return null;

    final requestId = ++_feedLoadGeneration;
    _lastLoadMoreRequestId = requestId;
    _isLoadingMore = true;
    _loadError = null;
    _notifyFeedChanged();

    try {
      if (kDebugMode) {
        debugPrint("Load More Triggered");
      }

      final response = await _postService.getPaginatedPosts(
        cursor: _nextCursor,
      );
      final posts = response.posts
          .where((post) => _isSupportedMediaUrl(post.media))
          .toList();

      if (posts.isNotEmpty) {
        _posts.addAll(posts);
        _mediaUrls.addAll(posts.map((e) => e.media));
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        _notifyFeedChanged();
        // Preload videos in background without blocking UI
        unawaited(
          _ensureControllersAroundIndex(_currentIndex.value, requestId),
        );
        if (kDebugMode) {
          debugPrint('Total Posts Count: ${_posts.length}');
        }
      } else {
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
      }

      if (requestId != _feedLoadGeneration) {
        if (kDebugMode) {
          debugPrint(
            'Load more request $requestId cancelled due to newer request',
          );
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${posts.length} more posts');
      }

      if (requestId != _feedLoadGeneration) {
        if (kDebugMode) {
          debugPrint(
            'Load more request $requestId cancelled due to newer request',
          );
        }
        return null;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("LOAD MORE ERROR: $e");
      }
      _loadError = 'Failed to load more posts';
      return null;
    } finally {
      _isLoadingMore = false;
      _notifyFeedChanged();
    }
  }

  Future<bool?> initVideos({bool refresh = false}) async {
    final requestId = ++_feedLoadGeneration;

    if (refresh) {
      // Prevent multiple simultaneous refreshes
      if (_isRefreshing) {
        if (kDebugMode) {
          debugPrint(
            '⏳ [VideoFeed] Refresh already in progress, skipping request $requestId',
          );
        }
        return null;
      }
      _lastRefreshRequestId = requestId;
      _isRefreshing = true;
    } else {
      // Prevent multiple simultaneous initial loads
      if (_isInitialLoading) {
        if (kDebugMode) {
          debugPrint(
            '⏳ [VideoFeed] Initial load already in progress, skipping request $requestId',
          );
        }
        return null;
      }
      _isInitialLoading = _mediaUrls.isEmpty;
    }

    _loadError = null;
    _notifyFeedChanged();

    try {
      if (kDebugMode) {
        debugPrint("${refresh ? "Refresh" : "Initial Load"} API Hit");
      }

      if (refresh) {
        _nextCursor = null;
        _hasMore = true;
        _isLoadingMore = false;
        _postService.resetPagination();
        // Don't clear posts for refresh - keep them visible
      }

      final response = await _postService.getPaginatedPosts(
        cursor: _nextCursor,
        refresh: refresh,
      );

      final posts = response.posts
          .where((post) => _isSupportedMediaUrl(post.media))
          .toList();

      if (response.posts.isEmpty) {
        if (kDebugMode) {
          debugPrint("API returned no posts");
        }
        if (!refresh) {
          // Only clear posts for initial load
          _posts = [];
          _mediaUrls = [];
        }
        _hasMore = false;
        _notifyFeedChanged();
      } else if (posts.isEmpty) {
        if (kDebugMode) {
          debugPrint("Posts received, but media URLs were empty or invalid");
        }
        if (!refresh) {
          // Only clear posts for initial load
          _posts = [];
          _mediaUrls = [];
        }
        _hasMore = response.hasMore;
        _nextCursor = response.nextCursor;
        _notifyFeedChanged();
      } else {
        if (refresh) {
          // For refresh: merge new posts at the top, avoid duplicates
          _mergeRefreshedPosts(posts);
        } else {
          // For initial load: replace all posts
          _posts = posts;
          _mediaUrls = _posts.map((e) => e.media).toList();
        }
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        _notifyFeedChanged();

        if (kDebugMode) {
          debugPrint('Total Posts Count: ${_posts.length}');
        }
      }

      if (gen != _feedLoadGeneration) return null;

      // Only dispose and recreate controllers for initial load, not refresh
      if (!refresh) {
        await _disposeAllControllers();
        _failedVideoIndexes.clear();
        _currentIndex.value = 0;
        _isPlaying.value = false;
      }

      // Preload videos in background without blocking UI
      unawaited(
        _ensureControllersAroundIndex(refresh ? _currentIndex.value : 0, gen),
      );

      if (!refresh) {
        playVideo(0);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Video load error: $e");
      }
      _loadError = 'Failed to load feed';
      return false;
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      _notifyFeedChanged();
    }
  }

  Map<String, dynamic> getCurrentVideoData() {
    if (_posts.isNotEmpty && _currentIndex.value < _posts.length) {
      final post = _posts[_currentIndex.value];
      return {
        "username": post.id,
        "caption": post.caption,
        "music": "Original audio",
        "postId": post.id,
        "likesCount": post.likesCount,
        "isLiked": post.isLiked,
      };
    }
    return {};
  }

  void playVideo(int index) {
    _currentIndex.value = index;
    unawaited(_ensureControllersAroundIndex(index, _feedLoadGeneration));

    final controller = _controllers[index];
    if (controller == null) {
      _pauseAllVideos();
      _isPlaying.value = false;
      return;
    }

    _pauseAllVideos();
    if (controller.value.isInitialized) {
      controller.play();
      _isPlaying.value = true;
    }
  }

  void pauseCurrentVideo() {
    final controller = _controllers[_currentIndex.value];
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
    final controller = _controllers[_currentIndex.value];
    if (controller == null || !controller.value.isInitialized) {
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

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Pause all videos first
    for (final controller in _controllers.values) {
      controller.pause();
    }

    // Then dispose
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
    _currentIndex.dispose();
    _isPlaying.dispose();
    _feedRevision.dispose();

    if (kDebugMode) {
      debugPrint('🧹 VideoFeedController fully disposed');
    }
  }

  bool _isSupportedMediaUrl(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null) {
      return false;
    }

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _disposeAllControllers() async {
    if (kDebugMode) {
      debugPrint('🗑️ Disposing all controllers');
    }
    for (final controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _ensureControllersAroundIndex(int index, int generation) async {
    if (_disposed || index < 0 || index >= _posts.length) {
      return;
    }

    final targetIndexes = <int>{};

    // ✅ TIKTOK STRATEGY: Preload current + next video for smooth swiping
    // Current video
    final currentUrl = _posts[index].media;
    if (currentUrl.toLowerCase().contains('.mp4')) {
      targetIndexes.add(index);
    }

    // Next video (preload for smooth transition)
    if (index + 1 < _posts.length) {
      final nextUrl = _posts[index + 1].media;
      if (nextUrl.toLowerCase().contains('.mp4')) {
        targetIndexes.add(index + 1);
      }
    }

    // ✅ Dispose videos that are NOT current or next
    final indexesToDispose = _controllers.keys
        .where((existingIndex) => !targetIndexes.contains(existingIndex))
        .toList();
    for (final mediaIndex in indexesToDispose) {
      final controller = _controllers.remove(mediaIndex);
      if (controller != null) {
        await controller.pause();
        await controller.dispose();
        if (kDebugMode) {
          debugPrint('🗑️ Disposed video at index $mediaIndex');
        }
      }
    }

    // ✅ Initialize current and next videos
    for (final mediaIndex in targetIndexes) {
      if (_controllers.containsKey(mediaIndex)) {
        continue;
      }

      final url = _posts[mediaIndex].media.trim();
      if (!_isSupportedMediaUrl(url)) {
        continue;
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      try {
        await controller.initialize();
      } catch (e) {
        await controller.dispose();
        _failedVideoIndexes.add(mediaIndex);
        _notifyFeedChanged();
        if (kDebugMode) {
          debugPrint('Video initialize failed at index $mediaIndex: $e');
        }
        continue;
      }

      if (_disposed || generation != _feedLoadGeneration) {
        await controller.dispose();
        return;
      }

      controller.setLooping(true);
      controller.setVolume(1.0);
      _failedVideoIndexes.remove(mediaIndex);
      _controllers[mediaIndex] = controller;
      _notifyFeedChanged();
      if (kDebugMode) {
        debugPrint('✅ Loaded video at index $mediaIndex');
      }
    }
  }

  void _pauseAllVideos() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
    if (kDebugMode) {
      debugPrint('⏸️ All videos paused');
    }
  }
}
