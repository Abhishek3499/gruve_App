import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../controllers/video_feed_controller.dart';
import 'video_overlay.dart';
import 'video_top_bar.dart';

class VideoFeed extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final Function(VideoFeedController)? onControllerReady;

  const VideoFeed({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.onControllerReady,
  });

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  late VideoFeedController _controller;
  late PageController _pageController;
  late List<VideoPlayerController> _controllers;

  String selectedContentTab = 'For You';

  @override
  void initState() {
    super.initState();

    _controller = VideoFeedController();
    _pageController = PageController(viewportFraction: 1.0);
    _controllers = _controller.controllers;

    _controller.initVideos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    _controller.playVideo(page);
    HapticFeedback.lightImpact();

    // Pre-fetch data when user reaches 60% of current posts for seamless UX
    final triggerIndex = (_controller.mediaUrls.length * 0.5).floor();
    if (page >= triggerIndex && _controller.hasMore && !_controller.isLoadingMore) {
      _controller.loadMorePosts();
    }
  }

  void _onVideoTap() {
    _controller.togglePlayPause();
  }

  void _onTabChanged(String tab) {
    setState(() {
      selectedContentTab = tab;
    });
  }

  bool _isNetworkMediaUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return false;
    }

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Widget _buildVideoPlayer(int index) {
    final url = _controller.mediaUrls[index].trim();

    print("UI URL: $url");

    final isVideo = url.toLowerCase().contains(".mp4");
    final isValidNetworkUrl = _isNetworkMediaUrl(url);

    int videoIndex = 0;
    for (int i = 0; i < index; i++) {
      if (_controller.mediaUrls[i].toLowerCase().contains(
        ".mp4",
      )) {
        videoIndex++;
      }
    }

    return GestureDetector(
      onTap: _onVideoTap,
      child: Stack(
        children: [
          Container(
            color: Colors.black,
            child: isVideo
                ? (_controllers.isNotEmpty &&
                      videoIndex < _controllers.length &&
                      _controllers[videoIndex]
                          .value
                          .isInitialized)
                    ? SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controllers[videoIndex]
                                .value
                                .size
                                .width,
                            height: _controllers[videoIndex]
                                .value
                                .size
                                .height,
                            child: VideoPlayer(
                              _controllers[videoIndex],
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                : isValidNetworkUrl
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (
                      context,
                      child,
                      progress,
                    ) {
                      print("Rendering image: $url");
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      print("Image load error: $error");
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
          ),
          VideoOverlay(
            selectedTab: selectedContentTab,
            onTabChanged: _onTabChanged,
            controller: _controller,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.currentIndex,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _controller.isPlaying,
          builder: (context, _) {
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await _controller.initVideos(refresh: true);
                  },
                  color: Colors.white,
                  backgroundColor: Colors.grey[800],
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: _onPageChanged,
                    itemCount: _controller.mediaUrls.length,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemBuilder: (context, index) {
                      final url = _controller.mediaUrls[index].trim();

                      print("UI URL: $url");

                      final isVideo = url.toLowerCase().contains(".mp4");
                      final isValidNetworkUrl = _isNetworkMediaUrl(url);

                      int videoIndex = 0;
                      for (int i = 0; i < index; i++) {
                        if (_controller.mediaUrls[i].toLowerCase().contains(
                          ".mp4",
                        )) {
                          videoIndex++;
                        }
                      }

                      return GestureDetector(
                        onTap: _onVideoTap,
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.black,
                              child: isVideo
                                  ? (_controllers.isNotEmpty &&
                                            videoIndex < _controllers.length &&
                                            _controllers[videoIndex]
                                                .value
                                                .isInitialized)
                                        ? SizedBox.expand(
                                            child: FittedBox(
                                              fit: BoxFit.cover,
                                              child: SizedBox(
                                                width: _controllers[videoIndex]
                                                    .value
                                                    .size
                                                    .width,
                                                height: _controllers[videoIndex]
                                                    .value
                                                    .size
                                                    .height,
                                                child: VideoPlayer(
                                                  _controllers[videoIndex],
                                                ),
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                  : isValidNetworkUrl
                                  ? Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        progress,
                                      ) {
                                        print("Rendering image: $url");
                                        if (progress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        print("Image load error: $error");
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.white,
                                            size: 50,
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                            ),
                            VideoOverlay(
                              selectedTab: selectedContentTab,
                              onTabChanged: _onTabChanged,
                              controller: _controller,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                VideoTopBar(
                  selectedTab: selectedContentTab,
                  onTabChanged: _onTabChanged,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
