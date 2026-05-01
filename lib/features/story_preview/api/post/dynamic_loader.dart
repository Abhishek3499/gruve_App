import 'dart:math';
import 'package:flutter/material.dart';

class DynamicLoader extends StatelessWidget {
  final double progress; // 0.0 to 100.0
  final double? size;
  final Color? color;

  const DynamicLoader({
    super.key,
    required this.progress,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final loaderSize = size ?? 100;
    final loaderColor = color ?? const Color(0xFFBB86FC);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 300), // Smooth transition
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(loaderSize, loaderSize),
          painter: LoaderPainter(value, color: loaderColor),
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
  final Color color;
  LoaderPainter(this.progress, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 8.0;

    // 1. Background Track (Light Circle)
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Progress Arc (The actual loading part)
    final progressPaint = Paint()
      ..color =
          color // Light purple glow color
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
