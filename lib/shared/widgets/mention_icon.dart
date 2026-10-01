import 'package:flutter/material.dart';

/// Speech bubble with an "@" inside, used for the mentions/tagged profile tab.
class MentionIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MentionIcon({super.key, this.size = 22.0, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _MentionIconPainter(color: color),
      ),
    );
  }
}

class _MentionIconPainter extends CustomPainter {
  final Color color;

  const _MentionIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.085;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final left = stroke / 2;
    final right = w - stroke / 2;
    final top = stroke / 2;
    final bottom = h * 0.80;
    final radius = w * 0.17;

    // Bubble body with a downward tail in the bottom centre.
    final bubble = Path()
      ..moveTo(left + radius, top)
      ..lineTo(right - radius, top)
      ..quadraticBezierTo(right, top, right, top + radius)
      ..lineTo(right, bottom - radius)
      ..quadraticBezierTo(right, bottom, right - radius, bottom)
      ..lineTo(w * 0.60, bottom)
      ..lineTo(w * 0.50, h - stroke / 2)
      ..lineTo(w * 0.40, bottom)
      ..lineTo(left + radius, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - radius)
      ..lineTo(left, top + radius)
      ..quadraticBezierTo(left, top, left + radius, top)
      ..close();
    canvas.drawPath(bubble, paint);

    final at = TextPainter(
      text: TextSpan(
        text: '@',
        style: TextStyle(
          color: color,
          fontSize: w * 0.58,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    at.paint(
      canvas,
      Offset((w - at.width) / 2, (bottom - at.height) / 2 + stroke / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MentionIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
