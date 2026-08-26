import 'package:flutter/material.dart';
import 'package:gruve_app/features/notification/domain/entities/notification_model.dart';
import 'package:gruve_app/features/notification/presentation/controller/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/notification/presentation/widgets/notification_tile.dart';
import 'package:gruve_app/features/notification/presentation/widgets/follow_tile.dart';

class NewSection extends StatelessWidget {
  final List<AppNotification> notifications;

  const NewSection({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 24, 38),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...notifications.map((n) {
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
                isRead: n.isRead,
                onTap: () => provider.markNotificationAsRead(n.id),
              );
            }
          }),
        ],
      ),
    );
  }
}
