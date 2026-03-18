import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class RightActionBar extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback? onGift;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onOptions;

  const RightActionBar({
    super.key,
    this.likeCount = 125000,
    this.commentCount = 8200,
    this.shareCount = 2100,
    this.onGift,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 300, // Increased height from default

      decoration: BoxDecoration(
        color: const Color(0x80990099),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// 🔥 Gift
          _ActionIcon(iconPath: AppAssets.gifticon, onTap: onGift, size: 60),

          /// 🔥 Like
          _ActionIcon(
            iconPath: AppAssets.likeicon,
            count: _formatCount(likeCount),
            onTap: onLike,
          ),
          const SizedBox(height: 12),

          /// 🔥 Comment
          _ActionIcon(
            iconPath: AppAssets.commenticon,
            count: _formatCount(commentCount),
            onTap: onComment,
          ),
          const SizedBox(height: 12),
          _ActionIcon(iconPath: AppAssets.share, onTap: onShare),
          const SizedBox(height: 12),

          /// 🔥 Three Dots Options
          _ActionIcon(iconPath: AppAssets.doticon, onTap: onOptions),

          /// 🔥 Indicator Dots
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// 🔥 Asset Icon Widget (ONLY ONE VERSION)
class _ActionIcon extends StatelessWidget {
  final String iconPath;
  final String? count;
  final VoidCallback? onTap;
  final double size;

  const _ActionIcon({
    required this.iconPath,
    this.count,
    this.onTap,
    this.size = 29,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, height: size, width: size),

          if (count != null) ...[
            const SizedBox(height: 4),
            Text(
              count!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class IndicatorDot extends StatelessWidget {
  final bool isActive;

  const IndicatorDot({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
