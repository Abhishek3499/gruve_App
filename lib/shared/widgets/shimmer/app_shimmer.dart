import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppShimmer — the ONE wrapper that drives ALL skeleton children on a screen.
//
// HOW IT WORKS:
//   Shimmer.fromColors creates a single AnimationController internally.
//   Every Container child with a solid color inside this widget gets the
//   shimmer sweep applied to it simultaneously — they all pulse in sync.
//
// USAGE:
//   AppShimmer(
//     child: Column(children: [
//       ShimmerBox(width: 120, height: 14),
//       ShimmerCircle(radius: 20),
//     ]),
//   )
//
// MISTAKE TO AVOID:
//   Never nest AppShimmer inside AppShimmer. One per screen section is enough.
//   Never put real content (text, images) inside AppShimmer — only placeholder
//   containers. Real content will get the shimmer color applied to it.
// ─────────────────────────────────────────────────────────────────────────────
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ShimmerBox — a rectangular placeholder.
//
// Use for: text lines, image thumbnails, buttons, cards.
// The color must be a SOLID color (not transparent) for shimmer to work.
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // IMPORTANT: must be a solid color — shimmer replaces this color
        color: AppColors.skeletonPlaceholder,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ShimmerCircle — a circular placeholder.
//
// Use for: avatars, profile pictures, action icons.
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerCircle extends StatelessWidget {
  final double radius;

  const ShimmerCircle({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: AppColors.skeletonPlaceholder,
        shape: BoxShape.circle,
      ),
    );
  }
}
