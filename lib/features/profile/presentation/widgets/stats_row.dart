import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class StatsRow extends StatelessWidget {
  final int subscribersCount;
  final int likesCount;
  final int videosCount;
  final VoidCallback? onSubscribersTap;
  final VoidCallback? onSubscribedTap;

  const StatsRow({
    super.key,
    this.subscribersCount = 0,
    this.likesCount = 0,
    this.videosCount = 0,
    this.onSubscribersTap,
    this.onSubscribedTap,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget buildStat(String number, String label, [VoidCallback? onTap]) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: content,
      ),
    );
  }

  Widget buildDivider() {
    return Container(
      height: 22,
      width: 1.1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildStat(
            _formatCount(subscribersCount),
            "Subscribers",
            onSubscribersTap,
          ),
          buildDivider(),
          buildStat(_formatCount(likesCount), "Subscribed", onSubscribedTap),
          buildDivider(),
          buildStat(_formatCount(videosCount), "Posts"),
        ],
      ),
    );
  }
}
