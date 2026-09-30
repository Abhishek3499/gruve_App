import 'package:flutter/material.dart';

class NavItem extends StatefulWidget {
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
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.selectedIndex == widget.index;
    final icon = widget.icon;
    final imagePath = widget.imagePath;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _isPressed ? 0.82 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ICON OR IMAGE with height animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(
                0,
                isActive ? -3.5 : 0,
                0,
              ),
              child: icon != null
                  ? Icon(
                      icon,
                      size: isActive ? 23 : 21,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    )
                  : Image.asset(
                      imagePath!,
                      width: isActive ? 24 : 22,
                      height: isActive ? 24 : 22,
                      color: isActive
                          ? Colors.white
                          : const Color(
                              0xABFFFFFF,
                            ),
                    ),
            ),

            const SizedBox(height: 2),

            /// WHITE DOT with scale and position animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform:
                  Matrix4.translationValues(0.0, isActive ? -5.0 : -2.5, 0.0)
                    ..multiply(
                      Matrix4.diagonal3Values(
                        isActive ? 1.2 : 1.0,
                        isActive ? 1.2 : 1.0,
                        1.0,
                      ),
                    ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 1 : 0,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
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
