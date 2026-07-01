import 'package:flutter/material.dart';
import 'app_shimmer.dart';

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
          colors: [Color(0xFF42174C), Color(0xFF212235)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 130),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF7D63D1).withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: const SizedBox(height: 720),
              ),
              AppShimmer(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 130),
                      width: double.infinity,
                      child: Column(
                        children: [
                          const SizedBox(height: 110),
                          const ProfileStatsShimmer(),
                          const SizedBox(height: 25),
                          const ProfileStoriesShimmer(),
                          const SizedBox(height: 20),
                          const ProfileTabsShimmer(
                            widths: [82, 118, 94],
                            height: 42,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: ProfileGridShimmer(itemCount: 9),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: 30,
                      left: 0,
                      right: 0,
                      child: _OwnProfileHeaderShimmer(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfileShimmer extends StatelessWidget {
  const UserProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(height: 120),
                ProfileStatsShimmer(),
                SizedBox(height: 20),
                ProfileStoriesShimmer(),
                SizedBox(height: 20),
                ProfileTabsShimmer(
                  widths: [94, 78],
                  height: 40,
                ),
                ProfileGridShimmer(itemCount: 9),
              ],
            ),
          ),
          const Column(
            children: [
              SizedBox(height: 20),
              _UserProfileHeaderShimmer(),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileStatsShimmer extends StatelessWidget {
  const ProfileStatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _StatColumnShimmer(width: 82),
          _DividerShimmer(),
          _StatColumnShimmer(width: 44),
          _DividerShimmer(),
          _StatColumnShimmer(width: 52),
        ],
      ),
    );
  }
}

class _StatColumnShimmer extends StatelessWidget {
  final double width;

  const _StatColumnShimmer({required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerBox(height: 22, width: 42, borderRadius: 8),
        const SizedBox(height: 6),
        ShimmerBox(height: 14, width: width, borderRadius: 8),
      ],
    );
  }
}

class _DividerShimmer extends StatelessWidget {
  const _DividerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1.2,
      color: Colors.white,
    );
  }
}

class ProfileStoriesShimmer extends StatelessWidget {
  const ProfileStoriesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 30, right: 12),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerCircle(radius: 32),
                SizedBox(height: 6),
                ShimmerBox(height: 12, width: 58, borderRadius: 8),
              ],
            ),
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

class ProfileGridShimmer extends StatelessWidget {
  final int itemCount;

  const ProfileGridShimmer({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, _) {
        return const ShimmerBox(
          height: double.infinity,
          width: double.infinity,
          borderRadius: 18,
        );
      },
    );
  }
}

class _OwnProfileHeaderShimmer extends StatelessWidget {
  const _OwnProfileHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            SizedBox(width: 20),
            Spacer(),
            ShimmerBox(height: 30, width: 30, borderRadius: 8),
            SizedBox(width: 20),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerCircle(radius: 50),
              SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 22, width: 150, borderRadius: 8),
                    SizedBox(height: 8),
                    ShimmerBox(height: 18, width: 100, borderRadius: 8),
                    SizedBox(height: 25),
                    ShimmerBox(height: 40, width: 160, borderRadius: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserProfileHeaderShimmer extends StatelessWidget {
  const _UserProfileHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              ShimmerBox(width: 44, height: 44, borderRadius: 22),
              Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerCircle(radius: 50),
              SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    ShimmerBox(width: 145, height: 22, borderRadius: 8),
                    SizedBox(height: 8),
                    ShimmerBox(width: 105, height: 16, borderRadius: 8),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ShimmerBox(
                            width: double.infinity,
                            height: 42,
                            borderRadius: 30,
                          ),
                        ),
                        SizedBox(width: 21),
                        ShimmerCircle(radius: 21),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
