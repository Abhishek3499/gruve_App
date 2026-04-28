import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:video_player/video_player.dart';

class VideoFeedController {
  static const int _prefetchVideoCount = 2;

  bool _disposed = false;
  int _feedLoadGeneration = 0;

  List<String> _mediaUrls = [];
  List<String> get mediaUrls => _mediaUrls;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  final PostService _postService = PostService();
  final Map<int, VideoPlayerController> _controllers =
      <int, VideoPlayerController>{};
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  bool _isLoadingMore = false;
  bool _hasMore = true;
  CursorModel? _nextCursor;

  VideoFeedController() {
    debugPrint("VideoFeedController initialized");
  }

  ValueNotifier<int> get currentIndex => _currentIndex;
  ValueNotifier<bool> get isPlaying => _isPlaying;
  List<VideoPlayerController> get controllers => _controllers.values.toList();
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  VideoPlayerController? controllerForMediaIndex(int mediaIndex) {
    return _controllers[mediaIndex];
  }

  Future<bool?> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return null;

    final gen = ++_feedLoadGeneration;
    _isLoadingMore = true;

    try {
      debugPrint("Load More Triggered");

      final response = await _postService.getPaginatedPosts(cursor: _nextCursor);
      final posts = response.posts
          .where((post) => _isSupportedMediaUrl(post.media))
          .toList();

      if (posts.isNotEmpty) {
        _posts.addAll(posts);
        _mediaUrls.addAll(posts.map((e) => e.media));
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        await _ensureControllersAroundIndex(_currentIndex.value, gen);
        debugPrint('Total Posts Count: ${_posts.length}');
      }

      debugPrint('Loaded ${posts.length} more posts');

      if (gen != _feedLoadGeneration) return null;
      return true;
    } catch (e) {
      debugPrint("LOAD MORE ERROR: $e");
      return null;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<bool?> initVideos({bool refresh = false}) async {
    final gen = ++_feedLoadGeneration;

    try {
      debugPrint("${refresh ? "Refresh" : "Initial Load"} API Hit");

      if (refresh) {
        _nextCursor = null;
        _hasMore = true;
        _isLoadingMore = false;
        _postService.resetPagination();
      }

      final response = await _postService.getPaginatedPosts(
        cursor: _nextCursor,
        refresh: refresh,
      );

      final posts = response.posts
          .where((post) => _isSupportedMediaUrl(post.media))
          .toList();

      if (response.posts.isEmpty) {
        debugPrint("API returned no posts");
        _posts = [];
        _mediaUrls = [];
        _hasMore = false;
      } else if (posts.isEmpty) {
        debugPrint("Posts received, but media URLs were empty or invalid");
        _posts = [];
        _mediaUrls = [];
      } else {
        _posts = posts;
        _mediaUrls = _posts.map((e) => e.media).toList();
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        debugPrint('Total Posts Count: ${_posts.length}');
      }

      if (gen != _feedLoadGeneration) return null;

      await _disposeAllControllers();

      _currentIndex.value = 0;
      _isPlaying.value = false;
      await _ensureControllersAroundIndex(0, gen);
      playVideo(0);

      return true;
    } catch (e) {
      debugPrint("Video load error: $e");
      return false;
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

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
    _currentIndex.dispose();
    _isPlaying.dispose();
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
    var bufferedVideos = 0;
    for (var i = index; i < _posts.length; i++) {
      final mediaUrl = _posts[i].media;
      if (!mediaUrl.toLowerCase().contains('.mp4')) {
        continue;
      }

      targetIndexes.add(i);
      bufferedVideos++;
      if (bufferedVideos > _prefetchVideoCount) {
        break;
      }
    }

    final indexesToDispose = _controllers.keys
        .where((existingIndex) => !targetIndexes.contains(existingIndex))
        .toList();
    for (final mediaIndex in indexesToDispose) {
      final controller = _controllers.remove(mediaIndex);
      await controller?.dispose();
    }

    for (final mediaIndex in targetIndexes) {
      if (_controllers.containsKey(mediaIndex)) {
        continue;
      }

      final url = _posts[mediaIndex].media.trim();
      if (!_isSupportedMediaUrl(url)) {
        continue;
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      if (_disposed || generation != _feedLoadGeneration) {
        await controller.dispose();
        return;
      }

      controller.setLooping(true);
      _controllers[mediaIndex] = controller;
    }

    if (_currentIndex.value == index) {
      _currentIndex.value = _currentIndex.value;
    }
  }

  void _pauseAllVideos() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }
}
