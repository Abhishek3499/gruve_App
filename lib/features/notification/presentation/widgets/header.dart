import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/notification/presentation/controller/notification_provider.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

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
              if (provider.unreadCount > 0)
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
                    provider.markAllNotificationsAsRead();
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
                onTap: () => provider.setUnreadOnly(false),
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
                        decoration: !provider.unreadOnly
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: Colors.white,
                        fontWeight:
                            !provider.unreadOnly ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => provider.setUnreadOnly(true),
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
                          if (provider.unreadCount > 0)
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
                                    provider.unreadCount > 99
                                        ? "99+"
                                        : provider.unreadCount.toString(),
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
                          decoration: provider.unreadOnly
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: Colors.white,
                          fontWeight:
                              provider.unreadOnly ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
