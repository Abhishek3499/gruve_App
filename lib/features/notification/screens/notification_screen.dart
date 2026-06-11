import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/widgets/shimmer/notification_shimmer.dart';
import 'package:gruve_app/features/notification/api/models/notification_model.dart';
import 'package:gruve_app/features/notification/providers/notification_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/header.dart';
import '../widgets/follow_tile.dart';
import '../widgets/notification_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.fetchInitialNotifications(showLoading: true);
      provider.fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().fetchNextPage();
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification n) {
    final provider = context.read<NotificationProvider>();
    final actorUsername = n.actor?.username ?? 'Someone';
    final profilePic = n.actor?.profilePicture ?? '';
    final timeDisplay = NotificationProvider.formatTime(n.createdAt);

    if (n.type == 'follow' || n.type == 'user_follow') {
      return FollowTile(
        username: actorUsername,
        time: timeDisplay,
        profileImage: profilePic,
        userId: n.actor?.id ?? '',
        isRead: n.isRead,
        onTap: () => provider.markNotificationAsRead(n.id),
      );
    } else {
      String msg = 'interacted with your post.';
      if (n.type == 'post_like' || n.type == 'like') {
        msg = 'liked your video.';
      } else if (n.type == 'comment' || n.type == 'post_comment') {
        msg = 'commented on your video.';
      } else if (n.type == 'comment_mention') {
        msg = 'mentioned you in a comment.';
      }
      return NotificationTile(
        username: actorUsername,
        message: msg,
        time: timeDisplay,
        profileImage: profilePic,
        postImage: n.postImage,
        isRead: n.isRead,
        onTap: () => provider.markNotificationAsRead(n.id),
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
              final provider = context.read<NotificationProvider>();
              await Future.wait([
                provider.fetchInitialNotifications(showLoading: false),
                provider.fetchUnreadCount(),
              ]);
            },
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                Widget content;

                if (provider.isLoading) {
                  content = const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Header(),
                        SizedBox(height: 12),
                        NotificationShimmer(itemCount: 8),
                      ],
                    ),
                  );
                } else if (provider.errorMessage.isNotEmpty) {
                  content = SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const Header(),
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  provider.fetchInitialNotifications(
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
                } else if (provider.notifications.isEmpty) {
                  content = const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Header(),
                        _EmptyNotifications(),
                      ],
                    ),
                  );
                } else {
                  final showNew = provider.newNotifications.isNotEmpty;
                  final showToday = provider.todayNotifications.isNotEmpty;
                  final showThisWeek = provider.thisWeekNotifications.isNotEmpty;
                  final showEarlier = provider.earlierNotifications.isNotEmpty;

                  content = SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Header(),
                        if (showNew) ...[
                          _buildSectionHeader("New"),
                          ...provider.newNotifications.map((n) => _buildNotificationTile(n)),
                        ],
                        if (showToday) ...[
                          _buildSectionHeader("Today"),
                          ...provider.todayNotifications.map((n) => _buildNotificationTile(n)),
                        ],
                        if (showThisWeek) ...[
                          _buildSectionHeader("This Week"),
                          ...provider.thisWeekNotifications.map((n) => _buildNotificationTile(n)),
                        ],
                        if (showEarlier) ...[
                          _buildSectionHeader("Earlier"),
                          ...provider.earlierNotifications.map((n) => _buildNotificationTile(n)),
                        ],
                        if (provider.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
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
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No notifications yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When you get notifications, they will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
