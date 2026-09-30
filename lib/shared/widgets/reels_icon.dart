import 'package:flutter/material.dart';

/// Custom-rendered Instagram Reels clapperboard icon.
class ReelsIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ReelsIcon({
    super.key,
    this.size = 22.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ReelsIconPainter(color: color),
      ),
    );
  }
}

class _ReelsIconPainter extends CustomPainter {
  final Color color;

  const _ReelsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Base rounded rectangle
    final baseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.24),
    );
    Path fullPath = Path()..addRRect(baseRRect);

    // 2. Horizontal dividing slit between clapper header and body
    final hSlit = Path()
      ..addRect(Rect.fromLTWH(-1, h * 0.27, w + 2, h * 0.08));

    // 3. Diagonal stripe cuts across the clapper header
    final diag1 = Path()
      ..moveTo(w * 0.20, -1)
      ..lineTo(w * 0.32, -1)
      ..lineTo(w * 0.48, h * 0.28)
      ..lineTo(w * 0.36, h * 0.28)
      ..close();

    final diag2 = Path()
      ..moveTo(w * 0.52, -1)
      ..lineTo(w * 0.64, -1)
      ..lineTo(w * 0.80, h * 0.28)
      ..lineTo(w * 0.68, h * 0.28)
      ..close();

    // 4. Center play triangle in the bottom body
    final playPath = Path()
      ..moveTo(w * 0.40, h * 0.52)
      ..lineTo(w * 0.65, h * 0.645)
      ..lineTo(w * 0.40, h * 0.77)
      ..close();

    // Subtract all cutouts from base
    fullPath = Path.combine(PathOperation.difference, fullPath, hSlit);
    fullPath = Path.combine(PathOperation.difference, fullPath, diag1);
    fullPath = Path.combine(PathOperation.difference, fullPath, diag2);
    fullPath = Path.combine(PathOperation.difference, fullPath, playPath);

    canvas.drawPath(fullPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ReelsIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
