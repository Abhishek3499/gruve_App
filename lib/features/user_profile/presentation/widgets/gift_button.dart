import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
        width: context.rw(44), // Thoda bada area touch ke liye (Accessibility)
        height: context.rh(44),
        alignment: Alignment.center,
        child: Image.asset(
          AppAssets.gifticon2,
          width: context.rw(22),
          height: context.rh(22),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
