import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../api_calls/profile/model/profile_stats_model.dart';

class UserStatsRow extends StatelessWidget {
  const UserStatsRow({super.key, required this.stats});

  final ProfileStatsModel stats;

  Widget buildStat(String number, String label) {
    return Column(
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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildStat(stats.subscribersCount.toString(), "subscribers"),
          buildDivider(),
          buildStat(stats.likesCount.toString(), "Likes"),
          buildDivider(),
          buildStat(stats.videosCount.toString(), "Videos"),
        ],
      ),
    );
  }
}
