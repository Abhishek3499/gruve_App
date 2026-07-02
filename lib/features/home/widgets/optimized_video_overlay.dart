import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/story_preview/providers/post_like_provider.dart';
import 'package:gruve_app/features/auth/token_storage.dart';

import '../models/subscribe_model.dart';
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
    _seedCurrentUser();
    _loadCurrentUserId();
  }

  @override
  void didUpdateWidget(covariant OptimizedVideoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.selectedTab != widget.selectedTab) {
      _seedCurrentUser();
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await TokenStorage.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _seedCurrentUser() {
    final index = widget.currentIndex;
    if (widget.controller.posts.isEmpty ||
        index < 0 ||
        index >= widget.controller.posts.length) {
      return;
    }

    final post = widget.controller.posts[index];
    final isSubscribedFeed = widget.selectedTab == 'Subscribed';
    _subscribeController.addOrUpdateUser(
      SubscribeModel(
        userId: post.userId,
        username: post.username,
        isSubscribed: isSubscribedFeed || post.isSubscribed,
      ),
    );
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
            initialIsSubscribed:
                widget.selectedTab == 'Subscribed' || post.isSubscribed,
            hasActiveStory: post.hasActiveStory,
            subscribeController: _subscribeController,
            onOwnProfileTap: widget.onOwnProfileTap,
            taggedUsers: post.taggedUsers,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 150,
          child: Selector<PostLikeProvider, (bool, int)>(
            key: ValueKey(post.id),
            selector: (_, likeProvider) => (
              likeProvider.isLiked(post),
              likeProvider.likesCount(post),
            ),
            builder: (context, likeState, _) {
              final isLiked = likeState.$1;
              final likeCount = likeState.$2;
              return RightActionBar(
                likeCount: likeCount,
                isLiked: isLiked,
                commentCount: post.commentsCount,
                shareCount: post.sharesCount,
                onGift: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const GiftPanel(),
                  );
                },
                onLike: () {
                  context.read<PostLikeProvider>().toggleLike(post);
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
                    builder: (context) => ShareBottomSheet(postId: post.id),
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
                      postId: post.id,
                    ),
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
