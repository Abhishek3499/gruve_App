import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/post_like_provider.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';


import 'package:gruve_app/features/home/presentation/widgets/video_user_info.dart';

import 'package:gruve_app/features/home/presentation/controller/video_feed_controller.dart';
import 'package:gruve_app/features/home/presentation/controller/subscribe_controller.dart';
import 'package:gruve_app/features/home/presentation/widgets/right_action_bar.dart';
import 'package:gruve_app/features/gifts/presentation/widgets/gift_panel.dart';
import 'package:gruve_app/features/video_options/presentation/widgets/video_options_sheet.dart';
import 'package:gruve_app/features/comments/presentation/widgets/comment_sheet.dart';
import 'package:gruve_app/features/share/presentation/screens/share_bottom_sheet.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d("🔧 INITIALIZING USERS FOR SUBSCRIBE CONTROLLER");

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

      AppLogger.d("📊 INITIALIZING WITH ${usersData.length} USERS FROM POSTS");
      _subscribeController.initializeUsers(usersData);
    } else {
      // Fallback dummy data
      final dummyUsers = <Map<String, dynamic>>[
        {'userId': 'user1', 'username': 'jenny_m'},
        {'userId': 'user2', 'username': 'alex_d'},
        {'userId': 'user3', 'username': 'sarah_k'},
      ];
      AppLogger.d("⚠️ INITIALIZING WITH DUMMY DATA (NO POSTS AVAILABLE)");
      _subscribeController.initializeUsers(dummyUsers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUserId = Provider.of<AuthStateManager>(context).currentUserId;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 280,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // User Info at Bottom Left
        Positioned(
          left: 0,
          right: 80,
          bottom: 72,
          child: AnimatedBuilder(
            animation: widget.controller.currentIndex,
            builder: (context, _) {
              final index = widget.controller.currentIndex.value;
              if (widget.controller.posts.isEmpty ||
                  index >= widget.controller.posts.length) {
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
                taggedUsers: post.taggedUsers,
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
              if (widget.controller.posts.isEmpty ||
                  index >= widget.controller.posts.length) {
                return const SizedBox.shrink();
              }
              final post = widget.controller.posts[index];

              return Consumer<PostLikeProvider>(
                builder: (context, likeProvider, _) {
                  return RightActionBar(
                    likeCount: likeProvider.likesCount(post),
                    isLiked: likeProvider.isLiked(post),
                    commentCount: post.commentsCount,
                    shareCount: post.sharesCount,

                    /// 🎁
                    onGift: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const GiftPanel(),
                      );
                    },

                    /// ❤️ LIKE (managed via provider)
                    onLike: () {
                      likeProvider.toggleLike(post);
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

                            AppLogger.d("💬 COUNT: ${post.commentsCount}");
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
                        builder: (context) => ShareBottomSheet(postId: post.id),
                      );
                    },

                    /// ⚙️ OPTIONS
                    onOptions: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => VideoOptionsSheet(
                          userId: post.userId,
                          currentUserId: loggedInUserId,
                          userName: post.username,
                          profileImage: post.profilePicture,
                          postId: post.id,
                        ),
                      );
                    },
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
