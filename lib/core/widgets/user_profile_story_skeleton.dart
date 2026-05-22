import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// Skeleton loader for user profile highlights (no "Add Story" button)
class UserProfileStorySkeleton extends StatelessWidget {
  final int itemCount;

  const UserProfileStorySkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 30),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildStorySkeleton();
          },
        ),
      ),
    );
  }

  /// Skeleton for other users' stories (no add button)
  Widget _buildStorySkeleton() {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient ring container with inner circle
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF212235),
              ),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.skeletonPlaceholder,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Username text placeholder
          SizedBox(
            width: 72,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.skeletonPlaceholder,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
