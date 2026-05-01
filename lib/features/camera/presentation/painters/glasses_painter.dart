import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../utils/camera_logger.dart';

class Point {
  final int x;
  final int y;
  
  const Point(this.x, this.y);
}


class GlassesPainter extends CustomPainter {
  final Face face;
  final Size imageSize;
  final Size widgetSize;
  final Color glassesColor;

  GlassesPainter({
    required this.face,
    required this.imageSize,
    required this.widgetSize,
    this.glassesColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glassesColor
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) {
      CameraLogger.logVerbose('Eye landmarks not available');
      return;
    }

    final leftEyePos = _scalePoint(Point(leftEye.position.x.toInt(), leftEye.position.y.toInt()));
    final rightEyePos = _scalePoint(Point(rightEye.position.x.toInt(), rightEye.position.y.toInt()));

    _drawGlasses(canvas, leftEyePos, rightEyePos, paint);
  }

  void _drawGlasses(Canvas canvas, Offset leftEye, Offset rightEye, Paint paint) {
    final eyeDistance = (rightEye - leftEye).distance;
    final glassesWidth = eyeDistance * 2.2;
    final glassesHeight = eyeDistance * 0.8;
    
    final center = Offset(
      (leftEye.dx + rightEye.dx) / 2,
      (leftEye.dy + rightEye.dy) / 2,
    );

    final leftLensCenter = Offset(
      center.dx - (eyeDistance * 0.5),
      center.dy,
    );

    final rightLensCenter = Offset(
      center.dx + (eyeDistance * 0.5),
      center.dy,
    );

    final lensRect = Size(glassesWidth * 0.45, glassesHeight);

    final leftLensRect = Rect.fromCenter(
      center: leftLensCenter,
      width: lensRect.width,
      height: lensRect.height,
    );

    final rightLensRect = Rect.fromCenter(
      center: rightLensCenter,
      width: lensRect.width,
      height: lensRect.height,
    );

    final bridgePaint = Paint()
      ..color = glassesColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final bridgeStart = Offset(
      leftLensRect.right,
      leftLensCenter.dy,
    );

    final bridgeEnd = Offset(
      rightLensRect.left,
      rightLensCenter.dy,
    );

    final templePaint = Paint()
      ..color = glassesColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final leftTempleEnd = Offset(
      leftLensRect.left - eyeDistance * 0.3,
      leftLensCenter.dy,
    );

    final rightTempleEnd = Offset(
      rightLensRect.right + eyeDistance * 0.3,
      rightLensCenter.dy,
    );

    final lensPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(leftLensRect, const Radius.circular(8)),
      lensPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rightLensRect, const Radius.circular(8)),
      lensPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(leftLensRect, const Radius.circular(8)),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rightLensRect, const Radius.circular(8)),
      paint,
    );

    canvas.drawLine(bridgeStart, bridgeEnd, bridgePaint);

    canvas.drawLine(
      Offset(leftLensRect.left, leftLensCenter.dy),
      leftTempleEnd,
      templePaint,
    );

    canvas.drawLine(
      Offset(rightLensRect.right, rightLensCenter.dy),
      rightTempleEnd,
      templePaint,
    );
  }

  Offset _scalePoint(Point point) {
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;

    return Offset(
      point.x.toDouble() * scaleX,
      point.y.toDouble() * scaleY,
    );
  }

  @override
  bool shouldRepaint(GlassesPainter oldDelegate) {
    return oldDelegate.face != face ||
           oldDelegate.imageSize != imageSize ||
           oldDelegate.widgetSize != widgetSize ||
           oldDelegate.glassesColor != glassesColor;
  }
}
