import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class StatsRow extends StatelessWidget {
  final int subscribersCount;
  final int likesCount;
  final int videosCount;
  final VoidCallback? onSubscribersTap;
  final VoidCallback? onSubscribedTap;
  final EdgeInsetsGeometry? padding;

  const StatsRow({
    super.key,
    this.subscribersCount = 0,
    this.likesCount = 0,
    this.videosCount = 0,
    this.onSubscribersTap,
    this.onSubscribedTap,
    this.padding,
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
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              height: 1.15,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildStat(
            _formatCount(videosCount),
            "posts",
          ),
          const SizedBox(width: 24),
          buildStat(
            _formatCount(subscribersCount),
            "subscribers",
            onSubscribersTap,
          ),
          const SizedBox(width: 24),
          buildStat(
            _formatCount(likesCount),
            "subscribed",
            onSubscribedTap,
          ),
        ],
      ),
    );
  }
}
