import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';

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
    this.commentCount = 0,
    this.shareCount = 0,
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
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionIcon(iconPath: AppAssets.gifticon, onTap: onGift, size: 30),

          const SizedBox(height: 12),

          /// ❤️ LIKE
          _ActionIcon(
            iconPath: isLiked
                ? AppAssets
                      .likeicon // ❤️ liked
                : AppAssets.like2, // 🤍 default white outline
            count: _formatCount(likeCount),
            onTap: onLike,
            size: 26,
            color: isLiked ? null : Colors.white,
          ),

          const SizedBox(height: 12),

          _ActionIcon(
            iconPath: AppAssets.commenticon,
            count: _formatCount(commentCount),
            onTap: onComment,
            size: 22,
            color: Colors.white,
          ),

          const SizedBox(height: 12),

          _ActionIcon(
            iconPath: AppAssets.share,
            count: _formatCount(shareCount),
            onTap: onShare,
            size: 22,
            color: Colors.white,
          ),

          const SizedBox(height: 12),

          _ActionIcon(
            icon: Icons.more_horiz,
            onTap: onOptions,
            size: 22,
            color: Colors.white,
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

class _ActionIcon extends StatefulWidget {
  final String? iconPath;
  final IconData? icon;
  final String? count;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  const _ActionIcon({
    this.iconPath,
    this.icon,
    this.count,
    this.onTap,
    this.size = 20,
    this.color,
  }) : assert(iconPath != null || icon != null);

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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward().then((_) {
      if (mounted) {
        _animController.reverse();
      }
    });
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
            if (widget.icon != null)
              Icon(
                widget.icon,
                size: widget.size,
                color: widget.color ?? Colors.white,
                shadows: const [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black54,
                    offset: Offset(0.0, 1.0),
                  ),
                ],
              )
            else if (widget.iconPath != null)
              Image.asset(
                widget.iconPath!,
                height: widget.size,
                width: widget.size,
                color: widget.color,
              ),

            if (widget.count != null) ...[
              const SizedBox(height: 1),
              Text(
                widget.count!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black54,
                      offset: Offset(0.0, 1.0),
                    ),
                  ],
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
