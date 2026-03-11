import 'package:flutter/material.dart';

class SwipeDeleteBackground extends StatelessWidget {
  final VoidCallback onDelete;

  const SwipeDeleteBackground({
    super.key,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF311B36), // Background color matching chat theme
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFF51829), // Red circular delete button
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
