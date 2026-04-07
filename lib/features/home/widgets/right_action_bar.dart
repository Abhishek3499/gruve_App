import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class RightActionBar extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final VoidCallback? onGift;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onOptions;

  const RightActionBar({
    super.key,
    this.likeCount = 0,
    this.commentCount = 8200,
    this.shareCount = 2100,
    this.isLiked = false, // ✅ correct
    this.onGift,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    print("🔥 RightActionBar rebuild | isLiked: $isLiked"); // ✅ DEBUG

    return SizedBox(
      width: 55,
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x80990099),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionIcon(iconPath: AppAssets.gifticon, onTap: onGift, size: 60),

            /// ❤️ LIKE
            _ActionIcon(
              iconPath: isLiked
                  ? AppAssets
                        .likeicon // ❤️ liked
                  : AppAssets.like2, // 🤍 default
              count: _formatCount(likeCount),
              onTap: onLike,
            ),

            const SizedBox(height: 12),

            _ActionIcon(
              iconPath: AppAssets.commenticon,
              count: _formatCount(commentCount),
              onTap: onComment,
            ),

            const SizedBox(height: 12),

            _ActionIcon(iconPath: AppAssets.share, onTap: onShare),

            const SizedBox(height: 12),

            _ActionIcon(iconPath: AppAssets.doticon, onTap: onOptions),
          ],
        ),
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
      onTap: () {
        print('👉 tapped: ${iconPath.split('/').last}'); // ✅ DEBUG
        onTap?.call();
      },
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
