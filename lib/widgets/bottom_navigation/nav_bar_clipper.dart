import 'package:flutter/material.dart';

class NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final borderPaint = Paint()
      ..color = const Color(0xFFFF3AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double center = size.width / 2;
    double bumpHeight = 10;
    double bumpWidth = 35;

    final path = Path();
    path.moveTo(0, bumpHeight); // start from left (offset down by bumpHeight)

    path.lineTo(center - bumpWidth, bumpHeight);

    // Curve UP in center
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

    path.lineTo(size.width, bumpHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
