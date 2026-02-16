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

  const RightActionBar({
    super.key,
    this.likeCount = 125000,
    this.commentCount = 8200,
    this.shareCount = 2100,
    this.onGift,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0x80990099),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// 🔥 Gift
          _ActionIcon(iconPath: AppAssets.gifticon, onTap: onGift),

          /// 🔥 Like
          _ActionIcon(
            iconPath: AppAssets.likeicon,
            count: _formatCount(likeCount),
            onTap: onLike,
          ),

          /// 🔥 Comment
          _ActionIcon(
            iconPath: AppAssets.commenticon,
            count: _formatCount(commentCount),
            onTap: onComment,
          ),

          /// 🔥 Share
          _ActionIcon(
            iconPath: AppAssets.doticon,
            count: _formatCount(shareCount),
            onTap: onShare,
          ),

          /// 🔥 Indicator Dots
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IndicatorDot(isActive: true),
              SizedBox(height: 4),
              _IndicatorDot(isActive: false),
              SizedBox(height: 4),
              _IndicatorDot(isActive: false),
            ],
          ),
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

  const _ActionIcon({required this.iconPath, this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, height: 24, width: 24),

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

class _IndicatorDot extends StatelessWidget {
  final bool isActive;

  const _IndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
