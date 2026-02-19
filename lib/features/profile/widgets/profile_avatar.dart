import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/assets.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final String? imagePath;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.radius = 20,
    this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7D63D1).withValues(alpha: 0.8),
              blurRadius: 30,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: const Color(0xFF7D63D1).withValues(alpha: 0.6),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundImage: AssetImage(imagePath ?? AppAssets.profile),
        ),
      ),
    );
  }
}
