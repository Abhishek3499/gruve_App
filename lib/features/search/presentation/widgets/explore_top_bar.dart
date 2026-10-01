import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/notification/presentation/notifiers/notification_notifier.dart';
import 'package:gruve_app/features/notification/presentation/screens/notification_screen.dart';

/// Profile + search on the left, "Discovery" title in the centre,
/// notifications on the right.
class ExploreTopBar extends ConsumerWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;

  const ExploreTopBar({
    super.key,
    required this.onProfileTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = ref.watch(
      currentUserNotifierProvider.select((s) => s.profileImageUrl),
    );
    final unread = ref.watch(
      notificationNotifierProvider.select((s) => s.unreadCount),
    );
    final size = context.rw(40);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(16),
        vertical: context.rh(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Discovery',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.rf(18),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _CircleButton(
                    size: size,
                    onTap: onProfileTap,
                    child: ClipOval(
                      child: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: size,
                              height: size,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  Image.asset(AppAssets.profile, fit: BoxFit.cover),
                            )
                          : Image.asset(
                              AppAssets.profile,
                              width: size,
                              height: size,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SizedBox(width: context.rw(10)),
                  _CircleButton(
                    size: size,
                    onTap: onSearchTap,
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: context.rw(22),
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _CircleButton(
                    size: size,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()),
                    ),
                    child: SizedBox(
                      width: context.rw(22),
                      height: context.rw(22),
                      child: Image.asset(
                        AppAssets.notification1,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;

  const _CircleButton({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: child,
      ),
    );
  }
}
