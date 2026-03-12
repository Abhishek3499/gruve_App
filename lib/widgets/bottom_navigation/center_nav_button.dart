import 'package:flutter/material.dart';

class CenterNavButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const CenterNavButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFCC44CC), Color(0xFF6A006A)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x99FF00FF),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
