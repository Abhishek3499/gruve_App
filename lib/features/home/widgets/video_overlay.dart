import 'package:flutter/material.dart';
import 'package:gruve_app/features/notification/screens/notification_screen.dart';
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

  Widget _buildTab(String text) {
    final bool isSelected = selectedTab == text;

    return GestureDetector(
      onTap: () => onTabChanged(text),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'syncopate',
              color: isSelected ? const Color(0xFF280131) : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 45 : 0,
            color: const Color(0xFF280131),
          ),
        ],
      ),
    );
  }
}
