import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';

import 'video_user_info.dart';

import '../controllers/video_feed_controller.dart';
import '../controllers/subscribe_controller.dart';
import 'right_action_bar.dart';
import '../../gifts/widgets/gift_panel.dart';
import '../../video_options/widgets/video_options_sheet.dart';
import '../../comments/widgets/comment_sheet.dart';
import '../../share/screens/share_bottom_sheet.dart';

class VideoOverlay extends StatefulWidget {
  final String selectedTab;
  final Function(String) onTabChanged;
  final VideoFeedController controller;
  final VoidCallback onOwnProfileTap;

  const VideoOverlay({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.controller,
    required this.onOwnProfileTap,
  });

  @override
  State<VideoOverlay> createState() => _VideoOverlayState();
}

// SAME imports...

class _VideoOverlayState extends State<VideoOverlay> {
  late final SubscribeController _subscribeController;

  @override
  void initState() {
    super.initState();
    _subscribeController = SubscribeController();
    _initializeUsers();
  }

  void _initializeUsers() {
    print("🔧 INITIALIZING USERS FOR SUBSCRIBE CONTROLLER");

    // Initialize with posts data when available
    if (widget.controller.posts.isNotEmpty) {
      final usersData = widget.controller.posts
          .map(
            (post) => {
              'userId': post.userId,
              'username': post.username,
              'isSubscribed': post.isSubscribed,
            },
          )
          .toList();

      print("📊 INITIALIZING WITH ${usersData.length} USERS FROM POSTS");
      _subscribeController.initializeUsers(usersData);
    } else {
      // Fallback dummy data
      final dummyUsers = <Map<String, dynamic>>[
        {'userId': 'user1', 'username': 'jenny_m'},
        {'userId': 'user2', 'username': 'alex_d'},
        {'userId': 'user3', 'username': 'sarah_k'},
      ];
      print("⚠️ INITIALIZING WITH DUMMY DATA (NO POSTS AVAILABLE)");
      _subscribeController.initializeUsers(dummyUsers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // User Info at Bottom Left
        Positioned(
          left: 0,
          right: 80,
          bottom: 72,
          child: AnimatedBuilder(
            animation: widget.controller.currentIndex,
            builder: (context, _) {
              final index = widget.controller.currentIndex.value;
              if (widget.controller.posts.isEmpty || index >= widget.controller.posts.length) {
                return const SizedBox.shrink();
              }
              final post = widget.controller.posts[index];

              return VideoUserInfo(
                username: post.username,
                caption: post.caption,
                musicTitle: "Original Audio - ${post.username}",
                userId: post.userId,
                profilePicture: post.profilePicture,
                initialIsSubscribed: post.isSubscribed,
                hasActiveStory: post.hasActiveStory,
                subscribeController: _subscribeController,
                onOwnProfileTap: widget.onOwnProfileTap,
              );
            },
          ),
        ),

        // Right Action Bar
        Positioned(
          right: 16,
          bottom: 150,
          child: AnimatedBuilder(
            animation: widget.controller.currentIndex,
            builder: (context, _) {
              final index = widget.controller.currentIndex.value;
              if (widget.controller.posts.isEmpty || index >= widget.controller.posts.length) {
                return const SizedBox.shrink();
              }
              final post = widget.controller.posts[index];

              return RightActionBar(
                likeCount: post.likesCount,
                isLiked: post.isLiked,
                commentCount: post.commentsCount,
                shareCount: 2100,

                /// 🎁
                onGift: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const GiftPanel(),
                  );
                },

                /// ❤️ LIKE (same as before)
                onLike: () {
                  final postId = post.id;

                  if (postId.isNotEmpty) {
                    setState(() {
                      post.isLiked = !post.isLiked;

                      if (post.isLiked) {
                        post.likesCount++;
                      } else {
                        post.likesCount--;
                      }
                    });

                    PostService().likePost(postId).then((success) async {
                      if (success) {
                        await ProfileCountRefreshBridge.notifyCountsChanged(
                          reason: 'post_like_toggled',
                        );
                      }
                    });
                  }
                },

                /// 💬 COMMENT
                onComment: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentSheet(
                      postId: post.id,
                      onCommentAdded: () {
                        setState(() {
                          post.commentsCount++; // 🔥 MAIN FIX
                        });

                        print("💬 COUNT: ${post.commentsCount}");
                      },
                    ),
                  );
                },

                /// 🔗 SHARE
                onShare: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ShareBottomSheet(),
                  );
                },

                /// ⚙️ OPTIONS
                onOptions: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const VideoOptionsSheet(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
