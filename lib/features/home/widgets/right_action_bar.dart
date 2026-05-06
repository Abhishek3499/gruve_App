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

class _ActionIcon extends StatefulWidget {
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
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward().then((_) => _animController.reverse());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(widget.iconPath, height: widget.size, width: widget.size),

            if (widget.count != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.count!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
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
