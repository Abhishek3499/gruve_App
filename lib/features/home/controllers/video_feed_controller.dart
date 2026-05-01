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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _loadError;
  CursorModel? _nextCursor;

  VideoFeedController() {
    if (kDebugMode) {
      debugPrint("VideoFeedController initialized");
    }
  }

  ValueNotifier<int> get currentIndex => _currentIndex;
  ValueNotifier<bool> get isPlaying => _isPlaying;
  ValueNotifier<int> get feedRevision => _feedRevision;
  List<VideoPlayerController> get controllers => _controllers.values.toList();
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get loadError => _loadError;

  void _notifyFeedChanged() {
    if (_disposed) return;
    _feedRevision.value++;
  }

  VideoPlayerController? controllerForMediaIndex(int mediaIndex) {
    return _controllers[mediaIndex];
  }

  bool hasVideoLoadFailed(int mediaIndex) {
    return _failedVideoIndexes.contains(mediaIndex);
  }

  Future<bool?> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return null;

    final gen = ++_feedLoadGeneration;
    _isLoadingMore = true;
    _loadError = null;
    _notifyFeedChanged();

    try {
      if (kDebugMode) {
        debugPrint("Load More Triggered");
      }

      final response = await _postService.getPaginatedPosts(cursor: _nextCursor);
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
        unawaited(_ensureControllersAroundIndex(_currentIndex.value, gen));
        if (kDebugMode) {
          debugPrint('Total Posts Count: ${_posts.length}');
        }
      } else {
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${posts.length} more posts');
      }

      if (gen != _feedLoadGeneration) return null;
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
    final gen = ++_feedLoadGeneration;
    _isInitialLoading = _mediaUrls.isEmpty;
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
        _notifyFeedChanged();
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
        _posts = [];
        _mediaUrls = [];
        _hasMore = false;
        _notifyFeedChanged();
      } else if (posts.isEmpty) {
        if (kDebugMode) {
          debugPrint("Posts received, but media URLs were empty or invalid");
        }
        _posts = [];
        _mediaUrls = [];
        _hasMore = response.hasMore;
        _nextCursor = response.nextCursor;
        _notifyFeedChanged();
      } else {
        _posts = posts;
        _mediaUrls = _posts.map((e) => e.media).toList();
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        _notifyFeedChanged();
        if (kDebugMode) {
          debugPrint('Total Posts Count: ${_posts.length}');
        }
      }

      if (gen != _feedLoadGeneration) return null;

      await _disposeAllControllers();
      _failedVideoIndexes.clear();

      _currentIndex.value = 0;
      _isPlaying.value = false;
      // Preload videos in background without blocking UI
      unawaited(_ensureControllersAroundIndex(0, gen));
      playVideo(0);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Video load error: $e");
      }
      _loadError = 'Failed to load feed';
      return false;
    } finally {
      _isInitialLoading = false;
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
    
    // ONLY load current video - no preloading
    final mediaUrl = _posts[index].media;
    if (mediaUrl.toLowerCase().contains('.mp4')) {
      targetIndexes.add(index);
    }

    // Aggressively dispose ALL other videos
    final indexesToDispose = _controllers.keys
        .where((existingIndex) => existingIndex != index)
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

    // Initialize ONLY current video
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
