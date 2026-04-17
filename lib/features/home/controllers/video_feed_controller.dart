import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';

import 'package:video_player/video_player.dart';

class VideoFeedController {
  bool _disposed = false;

  List<String> _mediaUrls = [];
  List<String> get mediaUrls => _mediaUrls;

  final PostService _postService = PostService();
  final List<VideoPlayerController> _controllers = [];
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  int _feedLoadGeneration = 0;
  List<Post> _posts = [];

  // Pagination state
  bool _isLoadingMore = false;
  bool _hasMore = true;
  CursorModel? _nextCursor;

  VideoFeedController() {
    print("VideoFeedController initialized");
  }

  ValueNotifier<int> get currentIndex => _currentIndex;
  ValueNotifier<bool> get isPlaying => _isPlaying;
  List<VideoPlayerController> get controllers => _controllers;
  List<Post> get posts => _posts;

  // Load more posts (pagination)
  Future<bool?> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return null;

    final gen = ++_feedLoadGeneration;
    _isLoadingMore = true;

    try {
      debugPrint("🔄 Load More Triggered");
      
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
        
        debugPrint('📊 Total Posts Count: ${_posts.length}');
      }

      debugPrint('📊 Loaded ${posts.length} more posts');

      if (gen != _feedLoadGeneration) return null;
      return true;
    } catch (e) {
      debugPrint("❌ LOAD MORE ERROR: $e");
      return null;
    } finally {
      _isLoadingMore = false;
    }
  }

  // Get pagination state
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<bool?> initVideos({bool refresh = false}) async {
    final gen = ++_feedLoadGeneration;

    try {
      debugPrint("📡 ${refresh ? "Refresh" : "Initial Load"} API Hit");

      // Reset pagination state on refresh
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
        debugPrint("❌ API returned no posts");
        _posts = [];
        _mediaUrls = [];
        _hasMore = false;
      } else if (posts.isEmpty) {
        debugPrint("❌ Posts received, but media URLs were empty or invalid");
        _posts = [];
        _mediaUrls = [];
      } else {
        // Append new posts to existing ones (for load more)
        if (refresh) {
          _posts = posts;
        } else {
          _posts.addAll(posts);
        }
        _mediaUrls = _posts.map((e) => e.media).toList();
        
        // Update pagination state
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        
        debugPrint('📊 Total Posts Count: ${_posts.length}');
      }

      if (gen != _feedLoadGeneration) return null;

      final next = <VideoPlayerController>[];

      for (final post in _posts) {
        final url = post.media;
        final isVideo = url.toLowerCase().contains(".mp4");

        if (!isVideo) {
          print("Image detected: $url");
          continue;
        }

        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await controller.initialize();

        if (gen != _feedLoadGeneration) {
          await controller.dispose();
          for (final c in next) {
            c.dispose();
          }
          return null;
        }

        controller.setLooping(true);
        next.add(controller);
      }

      for (final old in _controllers) {
        old.dispose();
      }

      _controllers
        ..clear()
        ..addAll(next);

      _currentIndex.value = 0;
      _isPlaying.value = false;
      playVideo(0);

      _currentIndex.notifyListeners();
      _isPlaying.notifyListeners();

      return true;
    } catch (e) {
      print("Video load error: $e");
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
    final controllerIndex = _videoControllerIndexForMediaIndex(index);
    if (controllerIndex == null) {
      _pauseAllVideos();
      _isPlaying.value = false;
      return;
    }

    _pauseAllVideos();

    final controller = _controllers[controllerIndex];
    if (controller.value.isInitialized) {
      controller.play();
      _isPlaying.value = true;
    }
  }

  void pauseCurrentVideo() {
    final controllerIndex = _videoControllerIndexForMediaIndex(
      _currentIndex.value,
    );
    if (controllerIndex == null) {
      _isPlaying.value = false;
      return;
    }

    final controller = _controllers[controllerIndex];
    if (controller.value.isPlaying) {
      controller.pause();
      _isPlaying.value = false;
    }
  }

  void togglePlayPause() {
    final controllerIndex = _videoControllerIndexForMediaIndex(
      _currentIndex.value,
    );
    if (controllerIndex == null) {
      return;
    }

    final controller = _controllers[controllerIndex];
    if (!controller.value.isInitialized) return;

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

    for (final controller in _controllers) {
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

  int? _videoControllerIndexForMediaIndex(int mediaIndex) {
    if (mediaIndex < 0 || mediaIndex >= _posts.length) {
      return null;
    }

    if (!_posts[mediaIndex].media.toLowerCase().contains('.mp4')) {
      return null;
    }

    var videoIndex = 0;
    for (var i = 0; i < mediaIndex; i++) {
      if (_posts[i].media.toLowerCase().contains('.mp4')) {
        videoIndex++;
      }
    }

    if (videoIndex >= _controllers.length) {
      return null;
    }

    return videoIndex;
  }

  void _pauseAllVideos() {
    for (final controller in _controllers) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }
}
