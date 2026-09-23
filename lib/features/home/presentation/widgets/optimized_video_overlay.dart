import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/post_like_notifier.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';

import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/features/home/presentation/widgets/video_user_info.dart';
import 'package:gruve_app/features/home/presentation/controllers/video_feed_controller.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/home/presentation/widgets/right_action_bar.dart';
import 'package:gruve_app/features/gifts/presentation/widgets/gift_panel.dart';
import 'package:gruve_app/features/video_options/presentation/widgets/video_options_sheet.dart';
import 'package:gruve_app/features/comments/presentation/widgets/comment_sheet.dart';
import 'package:gruve_app/features/share/presentation/screens/share_bottom_sheet.dart';

class OptimizedVideoOverlay extends ConsumerStatefulWidget {
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
  ConsumerState<OptimizedVideoOverlay> createState() =>
      _OptimizedVideoOverlayState();
}

class _OptimizedVideoOverlayState extends ConsumerState<OptimizedVideoOverlay> {
  late final SubscribeNotifier _subscribeController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _subscribeController = ref.read(subscribeNotifierProvider);
    _seedCurrentUser();
    // Sync + cached (populated at app startup) — avoids an async secure-storage
    // read on every swipe for a value that's only needed if Options is opened.
    _currentUserId = TokenStorage.getCurrentUserIdSync();
  }

  @override
  void didUpdateWidget(covariant OptimizedVideoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.selectedTab != widget.selectedTab) {
      _seedCurrentUser();
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
    if (widget.controller.posts.isEmpty ||
        index >= widget.controller.posts.length) {
      return const SizedBox.shrink();
    }
    final post = widget.controller.posts[index];

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
          child: Consumer(
            key: ValueKey(post.id),
            builder: (context, ref, _) {
              final isLiked = ref.watch(
                postLikeNotifierProvider.select((state) => state.isLiked(post)),
              );
              final likeCount = ref.watch(
                postLikeNotifierProvider.select(
                  (state) => state.likesCount(post),
                ),
              );
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
                  ref.read(postLikeNotifierProvider.notifier).toggleLike(post);
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
                      mediaUrl: post.playbackMediaUrl,
                      isVideo: post.isVideo,
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
