import 'package:flutter/material.dart';

/// Centralized loader colors - use these for all loading states
class AppLoaderColors {
  AppLoaderColors._();

  // Light shimmer colors (for dark backgrounds)
  static const Color shimmerBaseLight = Color(0xFF2A1B3D);
  static const Color shimmerHighlightLight = Color(0xFF3D2A54);
  static const Color skeletonPlaceholderLight = Color(0x1AFFFFFF);

  // Dark shimmer colors (for light backgrounds)
  static const Color shimmerBaseDark = Color(0xFFE0E0E0);
  static const Color shimmerHighlightDark = Color(0xFFF5F5F5);
  static const Color skeletonPlaceholderDark = Color(0xFFBDBDBD);

  // Loader colors
  static const Color loaderPrimary = Color(0xFF9544A7);
  static const Color loaderDark = Color(0xFFBB86FC);
  static const Color loaderLight = Colors.white;

  // Get shimmer colors based on brightness
  static Color getShimmerBase(Brightness brightness) {
    return brightness == Brightness.dark ? shimmerBaseLight : shimmerBaseDark;
  }

  static Color getShimmerHighlight(Brightness brightness) {
    return brightness == Brightness.dark
        ? shimmerHighlightLight
        : shimmerHighlightDark;
  }

  static Color getSkeletonPlaceholder(Brightness brightness) {
    return brightness == Brightness.dark
        ? skeletonPlaceholderLight
        : skeletonPlaceholderDark;
  }
}
