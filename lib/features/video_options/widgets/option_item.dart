import 'package:flutter/material.dart';

class OptionItem extends StatelessWidget {
  final String title;
  final String icon;
  final Color? iconColor;
  final Color? textColor;
  final bool hasArrow;
  final VoidCallback onTap;

  const OptionItem({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.textColor,
    this.hasArrow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x804B005D), // #4B005D80
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left side icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Image.asset(
                  icon,
                  width: 16,
                  height: 16,
                  color: iconColor ?? Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Middle text
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Right side arrow (only for Report)
            if (hasArrow)
              Icon(
                Icons.chevron_right,
                color: textColor ?? Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
