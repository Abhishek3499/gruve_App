import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/video_assets.dart';

class VideoFeedController {
  List<VideoPlayerController> _controllers = [];
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  ValueNotifier<int> get currentIndex => _currentIndex;
  ValueNotifier<bool> get isPlaying => _isPlaying;
  List<VideoPlayerController> get controllers => _controllers;

  VideoFeedController() {
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final videoPath in VideoAssets.videoPaths) {
      final controller = VideoPlayerController.asset(videoPath);
      controller.setLooping(true);
      _controllers.add(controller);
    }

    if (_controllers.isNotEmpty) {
      _controllers.first.initialize().then((_) {
        _isPlaying.value = true;
        _controllers.first.play();
      });
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
