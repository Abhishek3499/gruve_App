import 'package:flutter/material.dart';
import 'video_user_info.dart';

import 'right_action_bar.dart';

class VideoOverlay extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;

  const VideoOverlay({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top section with tabs
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center toggle tabs
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTab("Subscribed"),
                      const SizedBox(width: 12),
                      Container(
                        height: 20,
                        width: 1.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      _buildTab("For you"),
                    ],
                  ),
                  // Notification icon
                  Positioned(
                    right: 16,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF280131),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Left bottom section - User info
        Positioned(
          bottom: 80,
          left: 04,
          right: 80,
          child: VideoUserInfo(
            username: '_NamecoKato',
            caption: 'Signed different. Moved different. Vibes hit different.',
            musicTitle: 'Blinding Lights',

            onSubscribe: () {
              // Handle subscribe action
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
