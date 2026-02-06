import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../controllers/video_feed_controller.dart';
import 'video_overlay.dart';

class VideoFeed extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const VideoFeed({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  late VideoFeedController _controller;
  late PageController _pageController;
  late List<VideoPlayerController> _controllers;
  String _selectedContentTab = 'For You';

  @override
  void initState() {
    super.initState();
    _controller = VideoFeedController();
    _pageController = PageController();
    _controllers = _controller.controllers;
  }

  @override
  void didUpdateWidget(VideoFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    _controller.playVideo(page);
  }

  void _onVideoTap() {
    _controller.togglePlayPause();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.currentIndex,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _controller.isPlaying,
          builder: (context, _) {
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: _controllers.length,

              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: _onVideoTap,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: _controllers[index].value.isInitialized
                          ? AspectRatio(
                              aspectRatio:
                                  _controllers[index].value.aspectRatio,
                              child: VideoPlayer(_controllers[index]),
                            )
                          : const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
