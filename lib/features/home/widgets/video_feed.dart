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
    
    // Configure PageController for smooth scrolling
    _pageController = PageController(
      viewportFraction: 1.0,
      keepPage: true,
    );
    
    _controllers = _controller.controllers;
    
    // Notify parent that controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onControllerReady != null) {
        widget.onControllerReady!(_controller);
      }
    });
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
    // Add smooth transition
    _controller.playVideo(page);
    
    // Add haptic feedback for better UX
    HapticFeedback.lightImpact();
  }

  void _onVideoTap() {
    _controller.togglePlayPause();
  }

  void _onTabChanged(String tab) {
    setState(() {
      selectedContentTab = tab;
    });
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
                // Video PageView (scrollable content)
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: _controllers.length,
                  // Add smooth scrolling settings
                  physics: const BouncingScrollPhysics(),
                  pageSnapping: true,
                  // Add animation duration for smoother transitions
                  allowImplicitScrolling: true,

                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: _onVideoTap,
                      child: Stack(
                        children: [
                          // Video background
                          Container(
                            color: Colors.black,
                            child: _controllers[index].value.isInitialized
                                ? SizedBox.expand(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _controllers[index].value.size.width,
                                        height: _controllers[index].value.size.height,
                                        child: VideoPlayer(_controllers[index]),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          
                          // Video overlay UI (user info and right action bar only)
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

                // Fixed top bar (Subscribed/For You tabs and Notification icon)
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
