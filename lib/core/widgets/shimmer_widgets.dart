import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// Profile shimmer - mimics ProfileSkeleton layout
/// Use this as: if (isLoading) return ProfileShimmer();
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Profile image placeholder
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.skeletonPlaceholder,
              ),
            ),
            const SizedBox(height: 10),
            // Name placeholder
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.skeletonPlaceholder,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            // Username placeholder
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.skeletonPlaceholder,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 30),
            // Stats row placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) {
                return Column(
                  children: [
                    Container(
                      height: 14,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.skeletonPlaceholder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 30,
                      decoration: BoxDecoration(
                        color: AppColors.skeletonPlaceholder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 30),
            // Grid placeholder
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (_, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.skeletonPlaceholder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Post grid shimmer - mimics post grid layout
class PostGridShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const PostGridShimmer({
    super.key,
    this.itemCount = 9,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (_, _) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.skeletonPlaceholder,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
}

/// Story list shimmer - mimics story list layout
class StoryListShimmer extends StatelessWidget {
  final int itemCount;

  const StoryListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (_, _) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.skeletonPlaceholder,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.skeletonPlaceholder,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.skeletonPlaceholder,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
