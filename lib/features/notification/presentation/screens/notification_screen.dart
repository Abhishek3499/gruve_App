import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/notification/presentation/widgets/shimmer/notification_shimmer.dart';
import 'package:gruve_app/features/notification/domain/entities/notification_model.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/notification/presentation/notifiers/notification_notifier.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/profile/presentation/screens/post_detail/profile_post_detail_screen.dart';

import 'package:gruve_app/features/notification/presentation/widgets/header.dart';
import 'package:gruve_app/features/notification/presentation/widgets/follow_tile.dart';
import 'package:gruve_app/features/notification/presentation/widgets/notification_tile.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationNotifierProvider.notifier)
          .fetchInitialNotifications(showLoading: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    ref.read(notificationNotifierProvider.notifier).cancelActiveRequests();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(notificationNotifierProvider);
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: state.isLoading || state.isLoadingMore,
      hasMore: state.hasNextPage,
    )) {
      return;
    }
    ref
        .read(notificationNotifierProvider.notifier)
        .fetchNextPage(reason: 'scroll');
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rw(18),
        context.rh(20),
        context.rw(18),
        context.rh(10),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.rf(13),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification n) async {
    final notifier = ref.read(notificationNotifierProvider.notifier);

    // Always mark notification as read
    if (!n.isRead) {
      notifier.markNotificationAsRead(n.id);
    }

    // If it has a post_id, fetch the post and open it!
    if (n.postId != null && n.postId!.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      try {
        final postService = PostService();
        final post = await postService.fetchPostById(n.postId!);

        if (mounted) {
          Navigator.pop(context); // pop loading dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePostDetailScreen(
                post: post,
                allPosts: [post],
                initialIndex: 0,
                isOwnProfile: false,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // pop loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to load post: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNotificationTile(AppNotification n) {
    final actorUsername = n.actor?.username ?? 'Someone';
    final profilePic = n.actor?.profilePicture ?? '';
    final timeDisplay = NotificationNotifier.formatTime(n.createdAt);

    if (n.type == 'follow' || n.type == 'user_follow') {
      return FollowTile(
        username: actorUsername,
        time: timeDisplay,
        profileImage: profilePic,
        userId: n.actor?.id ?? '',
        isRead: n.isRead,
        onTap: () => _handleNotificationTap(n),
      );
    } else {
      String msg = 'interacted with your post.';
      if (n.type == 'post_like' || n.type == 'like') {
        msg = 'liked your video.';
      } else if (n.type == 'comment' || n.type == 'post_comment') {
        msg = 'commented on your video.';
      } else if (n.type == 'comment_mention') {
        msg = 'mentioned you in a comment.';
      } else if (n.type == 'post_tag' || n.type == 'tag') {
        msg = 'tagged you in a post.';
      }
      return NotificationTile(
        username: actorUsername,
        message: msg,
        time: timeDisplay,
        profileImage: profilePic,
        postImage: n.postImage,
        isRead: n.isRead,
        onTap: () => _handleNotificationTap(n),
        userId: n.actor?.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientTop, AppColors.gradientBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: AppColors.bottomBlack,
            onRefresh: () async {
              await ref
                  .read(notificationNotifierProvider.notifier)
                  .fetchInitialNotifications(showLoading: false);
            },
            child: Consumer(
              builder: (context, ref, child) {
                final (
                  isLoading,
                  errorMessage,
                  notifications,
                  isLoadingMore,
                ) = ref.watch(
                  notificationNotifierProvider.select(
                    (s) => (
                      s.isLoading,
                      s.errorMessage,
                      s.notifications,
                      s.isLoadingMore,
                    ),
                  ),
                );
                Widget content;

                if (isLoading) {
                  content = SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Header(),
                        SizedBox(height: context.rh(12)),
                        const NotificationShimmer(itemCount: 8),
                      ],
                    ),
                  );
                } else if (errorMessage.isNotEmpty) {
                  content = SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const Header(),
                        Container(
                          height: context.rh(300),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rw(24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: context.rw(48),
                              ),
                              SizedBox(height: context.rh(16)),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: context.rf(14),
                                ),
                              ),
                              SizedBox(height: context.rh(16)),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(
                                        notificationNotifierProvider.notifier,
                                      )
                                      .fetchInitialNotifications(
                                        showLoading: true,
                                      );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8E44B9),
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (notifications.isEmpty) {
                  content = const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(children: [Header(), _EmptyNotifications()]),
                  );
                } else {
                  // Grouping getters depend only on `notifications`, so
                  // deriving them here (instead of watching the full state)
                  // keeps this rebuild scoped to the fields actually used.
                  final grouped = NotificationState(
                    notifications: notifications,
                  );
                  final showNew = grouped.newNotifications.isNotEmpty;
                  final showToday = grouped.todayNotifications.isNotEmpty;
                  final showThisWeek = grouped.thisWeekNotifications.isNotEmpty;
                  final showEarlier = grouped.earlierNotifications.isNotEmpty;

                  content = SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Header(),
                        if (showNew) ...[
                          _buildSectionHeader("New"),
                          ...grouped.newNotifications.map(
                            (n) => _buildNotificationTile(n),
                          ),
                        ],
                        if (showToday) ...[
                          _buildSectionHeader("Today"),
                          ...grouped.todayNotifications.map(
                            (n) => _buildNotificationTile(n),
                          ),
                        ],
                        if (showThisWeek) ...[
                          _buildSectionHeader("This Week"),
                          ...grouped.thisWeekNotifications.map(
                            (n) => _buildNotificationTile(n),
                          ),
                        ],
                        if (showEarlier) ...[
                          _buildSectionHeader("Earlier"),
                          ...grouped.earlierNotifications.map(
                            (n) => _buildNotificationTile(n),
                          ),
                        ],
                        if (isLoadingMore)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.rh(24),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 20,
                        ),
                      ],
                    ),
                  );
                }

                return content;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.rh(400),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: context.rw(64),
            color: Colors.white.withValues(alpha: 0.3),
          ),
          SizedBox(height: context.rh(16)),
          Text(
            "No notifications yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: context.rf(16),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.rh(8)),
          Text(
            "When you get notifications, they will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: context.rf(12),
            ),
          ),
        ],
      ),
    );
  }
}
