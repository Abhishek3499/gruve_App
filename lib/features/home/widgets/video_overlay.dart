import 'package:flutter/material.dart';

import 'video_user_info.dart';
import '../controllers/video_feed_controller.dart';

import 'right_action_bar.dart';

class VideoOverlay extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;
  final VideoFeedController controller;

  const VideoOverlay({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left bottom section - User info
        Positioned(
          bottom: 80,
          left: 04,
          right: 80,
          child: AnimatedBuilder(
            animation: controller.currentIndex,
            builder: (context, _) {
              final videoData = controller.getCurrentVideoData();
              return VideoUserInfo(
                username: videoData['username'] ?? '',
                caption: videoData['caption'] ?? '',
                musicTitle: videoData['music'] ?? '',
                onSubscribe: () {
                  // Handle subscribe action
                },
              );
            },
          ),
        ),

        // Right side action bar
        Positioned(
          right: 16,
          bottom: 150,
          child: RightActionBar(
            likeCount: 125000,
            commentCount: 8200,
            shareCount: 2100,
            onGift: () {},
            onLike: () {},
            onComment: () {},
            onShare: () {},
          ),
        ),
      ],
    );
  }
}
