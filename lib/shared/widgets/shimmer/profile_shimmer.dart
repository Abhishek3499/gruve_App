import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/shared/widgets/profile_grid_style.dart';
import 'package:gruve_app/shared/widgets/shimmer/app_shimmer.dart';

/// Modern skeleton loader for own ProfileScreen matching the exact Instagram-style UI.
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF42174C), Color(0xFF9544A7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AppShimmer(
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Top Bar: [+] on left, [@username] center, [☰] on right
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: const [
                          ShimmerBox(height: 24, width: 24, borderRadius: 6),
                          Spacer(),
                          ShimmerBox(height: 20, width: 120, borderRadius: 6),
                          Spacer(),
                          ShimmerBox(height: 24, width: 24, borderRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Header: Avatar (Left) + Full Name & Stats (Right)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ShimmerCircle(radius: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ShimmerBox(
                                  height: 15,
                                  width: 110,
                                  borderRadius: 4,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _StatColumnShimmer(
                                        numberWidth: 24,
                                        labelWidth: 32,
                                      ),
                                    ),
                                    Expanded(
                                      child: _StatColumnShimmer(
                                        numberWidth: 28,
                                        labelWidth: 58,
                                      ),
                                    ),
                                    Expanded(
                                      child: _StatColumnShimmer(
                                        numberWidth: 28,
                                        labelWidth: 54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Bio Placeholder (2 lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(height: 12, width: 220, borderRadius: 4),
                          SizedBox(height: 5),
                          ShimmerBox(height: 12, width: 150, borderRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Action Buttons (Edit Profile & Share Profile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: const [
                          Expanded(
                            child: ShimmerBox(
                              height: 32.5,
                              width: double.infinity,
                              borderRadius: 16,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ShimmerBox(
                              height: 32.5,
                              width: double.infinity,
                              borderRadius: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),

                    /// Story Highlights
                    const ProfileStoriesShimmer(),
                    const SizedBox(height: 7),

                    /// Filter Tabs Placeholder (3 icons evenly spaced)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 36,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            ShimmerBox(height: 20, width: 20, borderRadius: 4),
                            ShimmerBox(height: 20, width: 20, borderRadius: 4),
                            ShimmerBox(height: 20, width: 20, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Straight Edge-to-Edge Grid
              const SliverPadding(
                padding: ProfileGridStyle.gridPadding,
                sliver: _ProfileGridShimmerSliver(itemCount: 9),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 65)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern skeleton loader for UserProfileScreen.
class UserProfileShimmer extends StatelessWidget {
  const UserProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF42174C), Color(0xFF9544A7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AppShimmer(
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Top Bar with Back Button placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: const [
                          ShimmerBox(height: 24, width: 24, borderRadius: 6),
                          Spacer(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    /// Avatar + User Info Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ShimmerCircle(radius: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                ShimmerBox(
                                  height: 18,
                                  width: 140,
                                  borderRadius: 4,
                                ),
                                SizedBox(height: 6),
                                ShimmerBox(
                                  height: 13,
                                  width: 90,
                                  borderRadius: 4,
                                ),
                                SizedBox(height: 6),
                                ShimmerBox(
                                  height: 12,
                                  width: 160,
                                  borderRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// Action Buttons (Subscribe, Message, Gift)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: const [
                          Expanded(
                            child: ShimmerBox(
                              height: 40,
                              width: double.infinity,
                              borderRadius: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ShimmerBox(
                              height: 40,
                              width: double.infinity,
                              borderRadius: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          ShimmerCircle(radius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// UserStatsRow
                    const ProfileStatsShimmer(),
                    const SizedBox(height: 14),

                    /// Highlights
                    const ProfileStoriesShimmer(),
                    const SizedBox(height: 7),

                    /// Filter Tabs (3 icons)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 36,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            ShimmerBox(height: 20, width: 20, borderRadius: 4),
                            ShimmerBox(height: 20, width: 20, borderRadius: 4),
                            ShimmerBox(height: 20, width: 20, borderRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverPadding(
                padding: ProfileGridStyle.gridPadding,
                sliver: _ProfileGridShimmerSliver(itemCount: 9),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileStatsShimmer extends StatelessWidget {
  const ProfileStatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1B0B2E).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF9333EA).withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Expanded(
              child: _UserStatColumnShimmer(numberWidth: 32, labelWidth: 60),
            ),
            _StatDividerShimmer(),
            Expanded(
              child: _UserStatColumnShimmer(numberWidth: 32, labelWidth: 60),
            ),
            _StatDividerShimmer(),
            Expanded(
              child: _UserStatColumnShimmer(numberWidth: 32, labelWidth: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDividerShimmer extends StatelessWidget {
  const _StatDividerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1.0,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _UserStatColumnShimmer extends StatelessWidget {
  final double numberWidth;
  final double labelWidth;

  const _UserStatColumnShimmer({
    required this.numberWidth,
    required this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShimmerBox(height: 16, width: numberWidth, borderRadius: 4),
        const SizedBox(height: 3),
        ShimmerBox(height: 11, width: labelWidth, borderRadius: 4),
      ],
    );
  }
}

class _StatColumnShimmer extends StatelessWidget {
  final double numberWidth;
  final double labelWidth;

  const _StatColumnShimmer({this.numberWidth = 26, required this.labelWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 16, width: numberWidth, borderRadius: 4),
          const SizedBox(height: 2),
          ShimmerBox(height: 12, width: labelWidth, borderRadius: 4),
        ],
      ),
    );
  }
}

class ProfileStoriesShimmer extends StatelessWidget {
  const ProfileStoriesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerCircle(radius: 29),
              SizedBox(height: 4),
              ShimmerBox(height: 11, width: 44, borderRadius: 4),
            ],
          );
        },
      ),
    );
  }
}

class ProfileTabsShimmer extends StatelessWidget {
  final List<double> widths;
  final double height;

  const ProfileTabsShimmer({
    super.key,
    required this.widths,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widths
          .map((w) => ShimmerBox(height: height, width: w, borderRadius: 30))
          .toList(),
    );
  }
}

class _ProfileGridShimmerSliver extends StatelessWidget {
  final int itemCount;

  const _ProfileGridShimmerSliver({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: ProfileGridStyle.gridDelegate,
      delegate: SliverChildBuilderDelegate((context, index) {
        return const ShimmerBox(
          height: double.infinity,
          width: double.infinity,
          borderRadius: ProfileGridStyle.tileRadius,
        );
      }, childCount: itemCount),
    );
  }
}

class ExploreGridShimmer extends StatelessWidget {
  final int itemCount;

  const ExploreGridShimmer({super.key, this.itemCount = 12});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        padding: ProfileGridStyle.gridPadding.copyWith(bottom: 65),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: ProfileGridStyle.gridDelegate,
        itemCount: itemCount,
        itemBuilder: (_, _) {
          return const ShimmerBox(
            height: double.infinity,
            width: double.infinity,
            borderRadius: ProfileGridStyle.tileRadius,
          );
        },
      ),
    );
  }
}

class ProfileGridShimmer extends StatelessWidget {
  final int itemCount;

  const ProfileGridShimmer({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: ProfileGridStyle.gridPadding,
        itemCount: itemCount,
        gridDelegate: ProfileGridStyle.gridDelegate,
        itemBuilder: (_, _) {
          return const ShimmerBox(
            height: double.infinity,
            width: double.infinity,
            borderRadius: ProfileGridStyle.tileRadius,
          );
        },
      ),
    );
  }
}
