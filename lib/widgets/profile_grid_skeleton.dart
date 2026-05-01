import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// Skeleton loader for profile grid with shimmer effect
class ProfileGridSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showDraftItem;

  const ProfileGridSkeleton({
    super.key,
    this.itemCount = 9,
    this.showDraftItem = true,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: showDraftItem ? itemCount + 1 : itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          // Show draft skeleton at first position if enabled
          if (showDraftItem && index == 0) {
            return _buildDraftSkeleton();
          }
          return _buildPostSkeleton();
        },
      ),
    );
  }

  Widget _buildDraftSkeleton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.skeletonPlaceholder,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.skeletonPlaceholder,
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.skeletonPlaceholder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostSkeleton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.skeletonPlaceholder,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
