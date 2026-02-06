import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class SocialLoginRow extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final double spacing;

  const SocialLoginRow({
    super.key,
    this.onGooglePressed,
    this.onApplePressed,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onGooglePressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Image.asset(AppAssets.googleIcon, width: 24, height: 24),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: onApplePressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Image.asset(AppAssets.appleIcon, width: 24, height: 24),
          ),
        ),
      ],
    );
  }
}
