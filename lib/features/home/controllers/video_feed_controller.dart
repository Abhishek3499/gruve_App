import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:video_player/video_player.dart';

class VideoFeedController {
  final PostService _postService = PostService();
  final List<VideoPlayerController> _controllers = [];
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  ValueNotifier<int> get currentIndex => _currentIndex;
  ValueNotifier<bool> get isPlaying => _isPlaying;
  List<VideoPlayerController> get controllers => _controllers;

  /// Get current video data from dummy reels list
  Map<String, String> getCurrentVideoData() {
    return {
      "username": "user_${_currentIndex.value}",
      "caption": "Sample caption",
      "music": "Sample music",
      "userId": "user_${_currentIndex.value}",
    };
  }

  Future<void> initVideos() async {
    try {
      print("📥 Fetching posts...");

      final posts = await _postService.getPosts();

      print("✅ POSTS: ${posts.length}");

      _controllers.clear();

      for (var post in posts) {
        String url = post.media;

        print("🎥 RAW URL: $url");

        // ✅ Fix relative URL
        if (!url.startsWith("http")) {
          url = dotenv.env['BASE_URL']! + url;
        }

        print("🌐 FINAL URL: $url");

        final controller = VideoPlayerController.networkUrl(Uri.parse(url));

        await controller.initialize();
        controller.setLooping(true);

        _controllers.add(controller);
      }

      if (_controllers.isNotEmpty) {
        _currentIndex.value = 0;
        _controllers.first.play();
        _isPlaying.value = true;
      }
    } catch (e) {
      print("❌ VIDEO LOAD ERROR: $e");
    }
  }

  void playVideo(int index) {
    if (index < 0 || index >= _controllers.length) return;

    _currentIndex.value = index;

    final controller = _controllers[index];
    controller.setLooping(true);
    if (controller.value.isInitialized) {
      controller.play();
      _isPlaying.value = true;
    } else {
      controller.initialize().then((_) {
        controller.play();
        _isPlaying.value = true;
      });
    }
  }

  void pauseCurrentVideo() {
    if (_controllers.isNotEmpty && _currentIndex.value < _controllers.length) {
      final controller = _controllers[_currentIndex.value];
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
        _isPlaying.value = false;
      }
    }
  }

  void togglePlayPause() {
    if (_controllers.isEmpty || _currentIndex.value >= _controllers.length) {
      return;
    }

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
