import 'package:flutter/material.dart';

/// MediaQuery-based responsive sizing helpers, scaled against a
/// 375x812 reference design (standard mobile mockup size).
extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.of(this).size;

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  /// Scales a horizontal value (widths, horizontal padding/margins).
  double rw(double value) => value * screenWidth / 375;

  /// Scales a vertical value (heights, vertical padding/margins, SizedBox height).
  double rh(double value) => value * screenHeight / 812;

  /// Scales a font size against screen width, clamped to avoid extreme sizes
  /// on very small or very large screens/tablets.
  double rf(double value) {
    final scale = (screenWidth / 375).clamp(0.85, 1.25);
    return value * scale;
  }
}
