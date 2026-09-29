import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/features/notification/presentation/notifiers/notification_notifier.dart';
import 'package:gruve_app/features/follow_requests/presentation/screens/follow_requests_screen.dart';

class Header extends ConsumerWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (unreadCount, unreadOnly) = ref.watch(
      notificationNotifierProvider.select((s) => (s.unreadCount, s.unreadOnly)),
    );
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              BackButton(
                color: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              const Text(
                "NOTIFICATIONS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'syncopate',
                ),
              ),
              const Spacer(),
              // Double checkmark to mark all as read
              if (unreadCount > 0)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                    maxWidth: 34,
                    maxHeight: 34,
                  ),
                  icon: const Icon(
                    Icons.done_all,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    notifier.markAllNotificationsAsRead();
                  },
                  tooltip: 'Mark all as read',
                )
              else
                const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => notifier.setUnreadOnly(false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      "All",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: !unreadOnly
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: Colors.white,
                        fontWeight: !unreadOnly
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => notifier.setUnreadOnly(true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: AssetImage(AppAssets.nprofile),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: -5,
                              bottom: -5,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8E44B9),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99
                                        ? "99+"
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Unread",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: unreadOnly
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: Colors.white,
                          fontWeight: unreadOnly
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SubscribersRequestsTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SubscribersRequestsTile extends StatelessWidget {
  const _SubscribersRequestsTile();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FollowRequestsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF2B2B2B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Subscribers requests",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Approve or ignore requests",
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
