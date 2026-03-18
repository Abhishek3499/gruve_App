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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ICON OR IMAGE with height animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, isActive ? -8 : 0, 0), // Increased from -4 to -8
              child: icon != null
                ? Icon(
                    icon, 
                    size: isActive ? 28 : 26, // Larger when active
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7)
                  )
                : Image.asset(
                    imagePath!, // 🔥 yahin se image aayegi
                    width: isActive ? 32 : 30, // Larger when active
                    height: isActive ? 32 : 30, // Larger when active
                    color: isActive 
                      ? Colors.white 
                      : const Color(0xABFFFFFF), // PNG ko white banane ke liye
                  ),
            ),

            const SizedBox(height: 6),

            /// WHITE DOT with scale animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.diagonal3Values(
                isActive ? 1.2 : 1.0, // Scale up when active
                isActive ? 1.2 : 1.0,
                1.0,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 1 : 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
