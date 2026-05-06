import 'package:flutter/material.dart';
import 'app_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationShimmer — skeleton for the notification screen.
//
// WHY THIS MATTERS:
//   The notification screen is 100% static hardcoded data right now.
//   When you wire it to a real API, this shimmer will show during the load.
//   It mirrors the NotificationTile layout (avatar + text + post thumbnail).
//
// LAYOUT MIRRORS:
//   Row = avatar circle + (username+message lines) + optional post thumbnail
//   Matches NotificationTile widget layout.
// ─────────────────────────────────────────────────────────────────────────────
class NotificationShimmer extends StatelessWidget {
  final int itemCount;

  const NotificationShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title placeholder
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ShimmerBox(width: 60, height: 14, borderRadius: 5),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (_, index) => _NotificationRowSkeleton(
              showThumbnail: index % 2 == 0,
              messageWidth: index % 3 == 0 ? 180.0 : (index % 3 == 1 ? 160.0 : 200.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRowSkeleton extends StatelessWidget {
  final bool showThumbnail;
  final double messageWidth;

  const _NotificationRowSkeleton({
    required this.showThumbnail,
    required this.messageWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Profile avatar
          const ShimmerCircle(radius: 22),
          const SizedBox(width: 12),
          // Username + message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 100, height: 12, borderRadius: 5),
                const SizedBox(height: 6),
                ShimmerBox(width: messageWidth, height: 11, borderRadius: 5),
                const SizedBox(height: 4),
                const ShimmerBox(width: 40, height: 10, borderRadius: 4),
              ],
            ),
          ),
          // Post thumbnail (only for like/comment notifications)
          if (showThumbnail) ...[
            const SizedBox(width: 12),
            const ShimmerBox(width: 44, height: 44, borderRadius: 8),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationSectionShimmer — wraps a full section (Today / New / This Week)
// with the same curved container style as the real sections.
// ─────────────────────────────────────────────────────────────────────────────
class NotificationSectionShimmer extends StatelessWidget {
  final Color backgroundColor;
  final double bottomLeftRadius;
  final int itemCount;

  const NotificationSectionShimmer({
    super.key,
    required this.backgroundColor,
    required this.bottomLeftRadius,
    this.itemCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomLeftRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: AppShimmer(
              child: ShimmerBox(width: 60, height: 14, borderRadius: 5),
            ),
          ),
          const SizedBox(height: 15),
          NotificationShimmer(itemCount: itemCount),
        ],
      ),
    );
  }
}
