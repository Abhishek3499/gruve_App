import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:video_player/video_player.dart';

/// ✅ ADD THIS (dummy fallback)
final List<Map<String, String>> dummyReels = [
  {
    "username": "rahul_verma",
    "caption": "Morning vibes ☀️",
    "music": "Kesariya",
  },
  {
    "username": "neha_style",
    "caption": "Chasing dreams ✨",
    "music": "Brown Munde",
  },
];

class VideoFeedController {
  List<String> _mediaUrls = [];
  List<String> get mediaUrls => _mediaUrls;

  final PostService _postService = PostService();

  /// ✅ FIX (semicolon missing)
  final List<VideoPlayerController> _controllers = [];

  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  int _feedLoadGeneration = 0;

  List<Post> _posts = [];

  VideoFeedController() {
    print("📹 VideoFeedController initialized");
  }

  ValueNotifier<int> get currentIndex => _currentIndex;
  ValueNotifier<bool> get isPlaying => _isPlaying;
  List<VideoPlayerController> get controllers => _controllers;

  Future<bool?> initVideos() async {
    final gen = ++_feedLoadGeneration;

    try {
      print("📥 Fetching posts...");

      final posts = await _postService.getPosts();

      if (posts.isEmpty) {
        print("⚠️ API empty → using dummy data");

        _posts = [];
        _mediaUrls = dummyReels.map((e) => "").toList();
      } else {
        _posts = posts;

        _mediaUrls = posts
            .map((e) => e.media)
            .where((url) => url.isNotEmpty)
            .toList();
      }

      print("🎯 FINAL MEDIA URL LIST:");
      for (var url in _mediaUrls) {
        print("👉 $url");
      }

      if (gen != _feedLoadGeneration) return null;

      final next = <VideoPlayerController>[];

      for (var post in posts) {
        String url = post.media;

        if (url.isEmpty) continue;

        final isVideo = url.toLowerCase().contains(".mp4");

        if (!isVideo) {
          print("🖼️ Image detected: $url");
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

      _controllers.clear();
      _controllers.addAll(next);

      if (_controllers.isNotEmpty) {
        _currentIndex.value = 0;
        _controllers.first.play();
        _isPlaying.value = true;
      }

      _currentIndex.notifyListeners();
      _isPlaying.notifyListeners();

      return true;
    } catch (e) {
      print("❌ VIDEO LOAD ERROR: $e");
      return false;
    }
  }

  /// ✅ ADD THIS (MISSING METHOD)
  Map<String, String> getCurrentVideoData() {
    if (_posts.isNotEmpty && _currentIndex.value < _posts.length) {
      final post = _posts[_currentIndex.value];

      return {
        "username": post.id,
        "caption": post.caption,
        "music": "Original audio",
        "postId": post.id,
      };
    }

    if (_currentIndex.value < dummyReels.length) {
      final reel = dummyReels[_currentIndex.value];

      return {
        "username": reel['username'] ?? '',
        "caption": reel['caption'] ?? '',
        "music": reel['music'] ?? '',
        "userId": reel['username'] ?? '',
      };
    }

    return {};
  }

  void playVideo(int index) {
    if (index < 0 || index >= _controllers.length) return;

    _currentIndex.value = index;

    final controller = _controllers[index];

    if (controller.value.isInitialized) {
      controller.play();
      _isPlaying.value = true;
    }
  }

  void pauseCurrentVideo() {
    if (_controllers.isNotEmpty && _currentIndex.value < _controllers.length) {
      final controller = _controllers[_currentIndex.value];

      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying.value = false;
      }
    }
  }

  void togglePlayPause() {
    if (_controllers.isEmpty || _currentIndex.value >= _controllers.length)
      return;

    final controller = _controllers[_currentIndex.value];

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
    for (final controller in _controllers) {
      controller.dispose();
    }

    _controllers.clear();
    _currentIndex.dispose();
    _isPlaying.dispose();
  }
}
