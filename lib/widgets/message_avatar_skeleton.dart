import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// Skeleton loader for message avatar list with shimmer effect
class MessageAvatarSkeleton extends StatelessWidget {
  final int avatarCount;

  const MessageAvatarSkeleton({
    super.key,
    this.avatarCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemCount: avatarCount,
          itemBuilder: (context, index) {
            return _buildAvatarSkeleton();
          },
        ),
      ),
    );
  }

  /// Skeleton for individual avatar
  Widget _buildAvatarSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle with shimmer
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.skeletonPlaceholder,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        // Username text placeholder
        SizedBox(
          width: 60,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.skeletonPlaceholder,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small skeleton loader for pagination (shown at end of list)
class MessageAvatarPaginationSkeleton extends StatelessWidget {
  const MessageAvatarPaginationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF72008D), // Purple background color
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
