import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class GiftButton extends StatelessWidget {
  final VoidCallback? onTap;

  const GiftButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // 👈 GestureDetector ki jagah InkWell use karo ripple effect ke liye
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44, // Thoda bada area touch ke liye (Accessibility)
        height: 44,
        alignment: Alignment.center,
        child: Image.asset(
          AppAssets.gifticon2,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
