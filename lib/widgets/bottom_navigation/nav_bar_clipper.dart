import 'package:flutter/material.dart';

class NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final borderPaint = Paint()
      ..shader =
          const LinearGradient(
            colors: [Color(0x99FF3AFF), Color(0x99990099)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          ) // ✅ fixed dynamic
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double center = size.width / 2;
    double bumpHeight = 10;
    double bumpWidth = 35;
    double radius = 18; // ✅ only for smooth corners

    final path = Path();

    // 🔹 LEFT START (rounded)
    path.moveTo(0, bumpHeight + radius);
    path.quadraticBezierTo(0, bumpHeight, radius, bumpHeight);

    // 🔹 TOP LINE BEFORE BUMP
    path.lineTo(center - bumpWidth, bumpHeight);

    // 🔹 CENTER BUMP (UNCHANGED)
    path.cubicTo(
      center - bumpWidth + 10,
      bumpHeight,
      center - 20,
      0,
      center,
      0,
    );
    path.cubicTo(
      center + 20,
      0,
      center + bumpWidth - 10,
      bumpHeight,
      center + bumpWidth,
      bumpHeight,
    );

    // 🔹 RIGHT SIDE (rounded)
    path.lineTo(size.width - radius, bumpHeight);
    path.quadraticBezierTo(
      size.width,
      bumpHeight,
      size.width,
      bumpHeight + radius,
    );

    // 🔹 RIGHT BOTTOM
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // 🔹 BOTTOM LEFT
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
