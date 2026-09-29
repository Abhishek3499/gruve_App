import 'package:flutter/material.dart';

/// Shared layout tokens for own-profile and user-profile post grids.
class ProfileGridStyle {
  ProfileGridStyle._();

  static const double tileRadius = 26;
  static const double spacing = 10;

  static final BorderRadius borderRadius = BorderRadius.circular(tileRadius);

  static const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
    childAspectRatio: 3 / 4,
  );

  static const gridPadding = EdgeInsets.fromLTRB(12, 12, 12, 0);

  /// Instagram-style count formatting: exact number (with thousand
  /// separators) below 10K, then abbreviated with one decimal (dropped
  /// when whole) above that — e.g. 1,001 / 10K / 12.3K / 1.2M.
  static String formatCount(int count) {
    if (count >= 1000000) {
      final double val = count / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (count >= 10000) {
      final double val = count / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}K';
    }
    return _withThousandsSeparator(count);
  }

  static String _withThousandsSeparator(int count) {
    final digits = count.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Rounded profile-grid cell wrapper (thumbnail, overlays, badges).
class ProfileGridTile extends StatelessWidget {
  final Widget child;

  const ProfileGridTile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: ProfileGridStyle.borderRadius, child: child);
  }
}
