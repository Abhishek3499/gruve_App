import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

import 'video_user_info.dart';
import '../controllers/video_feed_controller.dart';
import '../controllers/subscribe_controller.dart';
import 'right_action_bar.dart';
import '../../gifts/widgets/gift_panel.dart';
import '../../video_options/widgets/video_options_sheet.dart';
import '../../comments/widgets/comment_sheet.dart';
import '../../share/screens/share_bottom_sheet.dart';

class OptimizedVideoOverlay extends StatefulWidget {
  final String selectedTab;
  final Function(String) onTabChanged;
  final VideoFeedController controller;
  final VoidCallback onOwnProfileTap;
  final int currentIndex;

  const OptimizedVideoOverlay({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.controller,
    required this.onOwnProfileTap,
    required this.currentIndex,
  });

  @override
  State<OptimizedVideoOverlay> createState() => _OptimizedVideoOverlayState();
}

class _OptimizedVideoOverlayState extends State<OptimizedVideoOverlay> {
  late final SubscribeController _subscribeController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _subscribeController = SubscribeController();
    _initializeUsers();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await TokenStorage.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _initializeUsers() {
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
      _subscribeController.initializeUsers(usersData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.currentIndex;
    if (widget.controller.posts.isEmpty || index >= widget.controller.posts.length) {
      return const SizedBox.shrink();
    }
    final post = widget.controller.posts[index];

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 80,
          bottom: 72,
          child: VideoUserInfo(
            username: post.username,
            caption: post.caption,
            musicTitle: "Original Audio - ${post.username}",
            userId: post.userId,
            profilePicture: post.profilePicture,
            initialIsSubscribed: post.isSubscribed,
            hasActiveStory: post.hasActiveStory,
            subscribeController: _subscribeController,
            onOwnProfileTap: widget.onOwnProfileTap,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 150,
          child: RightActionBar(
            likeCount: post.likesCount,
            isLiked: post.isLiked,
            commentCount: post.commentsCount,
            shareCount: 2100,
            onGift: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const GiftPanel(),
              );
            },
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
            onComment: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentSheet(
                  postId: post.id,
                  onCommentAdded: () {
                    setState(() {
                      post.commentsCount++;
                    });
                  },
                ),
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
                builder: (context) => VideoOptionsSheet(
                  userId: post.userId,
                  currentUserId: _currentUserId,
                  userName: post.username,
                  profileImage: post.profilePicture,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
