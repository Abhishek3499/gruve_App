import 'dart:math';
import 'package:flutter/material.dart';

class DynamicLoader extends StatelessWidget {
  final double progress; // 0.0 to 100.0

  const DynamicLoader({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 300), // Smooth transition
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: LoaderPainter(value),
          child: Center(
            child: Text(
              "${value.toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoaderPainter extends CustomPainter {
  final double progress;
  LoaderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 8.0;

    // 1. Background Track (Light Circle)
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Progress Arc (The actual loading part)
    final progressPaint = Paint()
      ..color =
          const Color(0xFFBB86FC) // Light purple glow color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap
          .round // Rounded edges for production look
      ..strokeWidth = strokeWidth;

    // Flutter draws from 3 o'clock, so -pi/2 starts it from top (12 o'clock)
    double sweepAngle = (2 * pi * (progress / 100));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
