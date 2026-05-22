import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// Production-level shimmer loading widget for dark themes
/// Use this for professional skeleton loading states
class ShimmerLoading extends StatelessWidget {
  final ShimmerType type;
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.type = ShimmerType.profile,
    this.width,
    this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: _buildShape(),
    );
  }

  Widget _buildShape() {
    switch (type) {
      case ShimmerType.circle:
        return Container(
          width: width ?? 80,
          height: height ?? 80,
          decoration: BoxDecoration(
            color: AppColors.skeletonPlaceholder,
            shape: BoxShape.circle,
          ),
        );
      case ShimmerType.rectangle:
        return Container(
          width: width ?? double.infinity,
          height: height ?? 100,
          decoration: BoxDecoration(
            color: AppColors.skeletonPlaceholder,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      case ShimmerType.textLine:
        return Container(
          width: width ?? 120,
          height: height ?? 14,
          decoration: BoxDecoration(
            color: AppColors.skeletonPlaceholder,
            borderRadius: BorderRadius.circular(borderRadius / 2),
          ),
        );
      case ShimmerType.smallCircle:
        return Container(
          width: width ?? 40,
          height: height ?? 40,
          decoration: BoxDecoration(
            color: AppColors.skeletonPlaceholder,
            shape: BoxShape.circle,
          ),
        );
      case ShimmerType.profile:
        return _buildProfileSkeleton();
    }
  }

  Widget _buildProfileSkeleton() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: AppColors.skeletonPlaceholder,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer type enum
enum ShimmerType { circle, rectangle, textLine, smallCircle, profile }

/// Professional profile skeleton with shimmer animation
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

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
            // Profile image
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.skeletonPlaceholder,
              ),
            ),
            const SizedBox(height: 10),
            // Name
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.skeletonPlaceholder,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            // Username
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.skeletonPlaceholder,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 30),
            // Stats row
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

/// Grid skeleton for profile posts
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridSkeleton({super.key, this.itemCount = 9, this.crossAxisCount = 3});

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

/// List item skeleton
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.skeletonPlaceholder,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 80,
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
      ),
    );
  }
}

/// Custom circular progress indicator with theme colors
class ThemeLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool isCentered;

  const ThemeLoader({
    super.key,
    this.size = 36,
    this.strokeWidth = 3,
    this.color,
    this.isCentered = true,
  });

  @override
  Widget build(BuildContext context) {
    final loader = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.loaderPrimary,
        ),
      ),
    );

    if (!isCentered) return loader;

    return Center(child: loader);
  }
}

/// Custom progress loader with customizable color
class CustomLoader extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final double strokeWidth;
  final bool showPercentage;

  const CustomLoader({
    super.key,
    required this.progress,
    this.size = 100,
    this.color = AppColors.loaderDark,
    this.strokeWidth = 8,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _LoaderPainter(
            progress: value,
            color: color,
            strokeWidth: strokeWidth,
          ),
          child: showPercentage
              ? Center(
                  child: Text(
                    "${value.toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoaderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * 3.14159 * (progress / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
