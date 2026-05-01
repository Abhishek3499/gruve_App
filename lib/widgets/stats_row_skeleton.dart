import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// Skeleton loader for stats row with shimmer effect
class StatsRowSkeleton extends StatelessWidget {
  const StatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatSkeleton("Subscribers"),
          _buildDividerSkeleton(),
          _buildStatSkeleton("Likes"),
          _buildDividerSkeleton(),
          _buildStatSkeleton("Videos"),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton(String label) {
    return Column(
      children: [
        // Only number placeholder gets shimmer effect
        Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.skeletonPlaceholder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Text label with original color (no shimmer)
        Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDividerSkeleton() {
    return Container(
      height: 40,
      width: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }
}
