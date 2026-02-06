import 'package:flutter/material.dart';

class NavItem extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    this.icon,
    this.imagePath,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  }) : assert(icon != null || imagePath != null);

  @override
  Widget build(BuildContext context) {
    final bool isActive = selectedIndex == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ICON OR IMAGE
          if (icon != null)
            Icon(icon, size: 26, color: Colors.white)
          else
            Image.asset(
              imagePath!, // 🔥 yahin se image aayegi
              width: 30,
              height: 30,
              color: const Color(0xABFFFFFF), // PNG ko white banane ke liye
            ),

          const SizedBox(height: 6),

          /// WHITE DOT
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 1 : 0,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
