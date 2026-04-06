import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';

import 'video_user_info.dart';

import '../controllers/video_feed_controller.dart';
import '../controllers/subscribe_controller.dart';
import 'right_action_bar.dart';
import '../../gifts/widgets/gift_panel.dart';
import '../../video_options/widgets/video_options_sheet.dart';
import '../../video_options/sheets/comment_sheet.dart';
import '../../share/screens/share_bottom_sheet.dart';

class VideoOverlay extends StatefulWidget {
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
  State<VideoOverlay> createState() => _VideoOverlayState();
}

class _VideoOverlayState extends State<VideoOverlay> {
  late final SubscribeController _subscribeController;
  int _likeCount = 125000;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _subscribeController = SubscribeController();
    _initializeUsers(); // (UI same rakhne ke liye rehne diya)
  }

  void _initializeUsers() {
    final dummyUsers = [
      {'userId': 'user1', 'username': 'jenny_m'},
      {'userId': 'user2', 'username': 'alex_d'},
      {'userId': 'user3', 'username': 'sarah_k'},
    ];
    _subscribeController.initializeUsers(dummyUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// LEFT BOTTOM USER INFO
        Positioned(
          bottom: 80,
          left: 4, // ✅ FIX (04 → 4)
          right: 80,
          child: AnimatedBuilder(
            animation: widget.controller.currentIndex,
            builder: (context, _) {
              final videoData = widget.controller.getCurrentVideoData();

              return VideoUserInfo(
                username: videoData['username'] ?? 'user',
                caption: videoData['caption'] ?? '',
                musicTitle: videoData['music'] ?? 'Original audio',
                userId: videoData['userId'] ?? 'user1',
                subscribeController: _subscribeController,
              );
            },
          ),
        ),

        /// RIGHT ACTION BAR
        Positioned(
          right: 16,
          bottom: 150,
          child: RightActionBar(
            likeCount: 125000,
            commentCount: 8200,
            shareCount: 2100,

            onGift: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: false,
                backgroundColor: Colors.transparent,
                builder: (context) => const GiftPanel(),
              );
            },

            onLike: () {
              final data = widget.controller.getCurrentVideoData();
              final postId = data['postId'];

              if (postId != null && postId.isNotEmpty) {
                PostService().likePost(postId);

                setState(() {
                  if (_isLiked) {
                    _likeCount--;
                    _isLiked = false;
                  } else {
                    _likeCount++;
                    _isLiked = true;
                  }
                });
              }
            },
            onComment: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CommentSheet(),
              );
            },

            onShare: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ShareBottomSheet(),
              );
            },

            onOptions: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const VideoOptionsSheet(),
              );
            },
          ),
        ),
      ],
    );
  }
}
