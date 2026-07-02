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
}

/// Rounded profile-grid cell wrapper (thumbnail, overlays, badges).
class ProfileGridTile extends StatelessWidget {
  final Widget child;

  const ProfileGridTile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: ProfileGridStyle.borderRadius,
      child: child,
    );
  }
}
