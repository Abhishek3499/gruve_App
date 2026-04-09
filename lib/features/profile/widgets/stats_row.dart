import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatsRow extends StatelessWidget {
  final int subscribersCount;
  final int likesCount;
  final int videosCount;

  const StatsRow({
    super.key,
    this.subscribersCount = 0,
    this.likesCount = 0,
    this.videosCount = 0,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

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
          style: const TextStyle(color: AppColors.white, fontSize: 14),
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
          buildStat(_formatCount(subscribersCount), "Subscribers"),
          buildDivider(),
          buildStat(_formatCount(likesCount), "Likes"),
          buildDivider(),
          buildStat(_formatCount(videosCount), "Videos"),
        ],
      ),
    );
  }
}
