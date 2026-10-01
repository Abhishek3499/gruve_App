import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/domain/entities/profile_stats_model.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class UserStatsRow extends StatelessWidget {
  const UserStatsRow({
    super.key,
    required this.stats,
    this.onSubscribersTap,
    this.onSubscribedTap,
  });

  final ProfileStatsModel stats;
  final VoidCallback? onSubscribersTap;
  final VoidCallback? onSubscribedTap;

  Widget buildStat(String number, String label, [VoidCallback? onTap]) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16.6,
              fontWeight: FontWeight.w600, // SemiBold
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
              fontWeight: FontWeight.w400, // Regular
              height: 1.15,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: content,
      ),
    );
  }

  Widget buildDivider() {
    return Container(
      height: 24,
      width: 1.0,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1B0B2E).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF9333EA).withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: buildStat(
                stats.subscribersCount.toString(),
                "Subscribers",
                onSubscribersTap,
              ),
            ),
            buildDivider(),
            Expanded(
              child: buildStat(
                stats.likesCount.toString(),
                "Subscribed",
                onSubscribedTap,
              ),
            ),
            buildDivider(),
            Expanded(child: buildStat(stats.videosCount.toString(), "Posts")),
          ],
        ),
      ),
    );
  }
}
