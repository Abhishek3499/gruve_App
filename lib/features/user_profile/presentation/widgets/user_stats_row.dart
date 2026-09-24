import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.white70, fontSize: 14),
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
      height: 40,
      width: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rw(40)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildStat(
            stats.subscribersCount.toString(),
            "Subscribers",
            onSubscribersTap,
          ),
          buildDivider(),
          buildStat(
            stats.likesCount.toString(),
            "Subscribed",
            onSubscribedTap,
          ),
          buildDivider(),
          buildStat(stats.videosCount.toString(), "Posts"),
        ],
      ),
    );
  }
}
