import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter that draws a circular track and an animated sweep gradient arc
/// using Gruve's signature purple/pink gradient palette.
class GradientCircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final bool isFailed;
  final double strokeWidth;

  const GradientCircularProgressPainter({
    required this.progress,
    required this.isCompleted,
    required this.isFailed,
    this.strokeWidth = 3.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 7.0) / 2;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0 && !isCompleted && !isFailed) return;

    // 2. Active Progress Arc with Gruve Purple/Pink Gradient
    final rect = Rect.fromCircle(center: center, radius: radius);

    final List<Color> gradientColors = isFailed
        ? const [Color(0xFFE53935), Color(0xFFFF7043)]
        : const [
            Color(0xFFFF3AFF), // Neon Pink/Magenta
            Color(0xFFC358D7), // Gruve Purple Accent
            Color(0xFF9544A7), // Deep Loader Purple
            Color(0xFFD42BC2), // Vibrant Magenta
            Color(0xFFFF3AFF), // Neon Pink/Magenta
          ];

    final sweepGradient = SweepGradient(
      colors: gradientColors,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isFailed != isFailed ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
