import 'package:flutter/material.dart';

class SlantedCardClipper extends CustomClipper<Path> {
  final double slantOffset;
  final double radius;
  final double obtuseRadius;

  const SlantedCardClipper({
    this.slantOffset = 25.0,
    this.radius = 12.0,
    this.obtuseRadius = 20.0,
  });

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;

    final double activeSlant =
        (h < 90.0) ? (slantOffset * h / 90.0) : slantOffset;
    final double activeRadius = (h < 90.0) ? (radius * h / 90.0) : radius;
    final double activeObtuseRadius =
        (h < 90.0) ? (obtuseRadius * h / 90.0) : obtuseRadius;

    final path = Path();
    path.moveTo(activeRadius, 0);
    path.lineTo(w - activeRadius, 0);
    path.quadraticBezierTo(w, 0, w, activeRadius);
    path.lineTo(w, h - activeRadius);
    path.quadraticBezierTo(w, h, w - activeRadius, h);
    path.lineTo(activeSlant + activeObtuseRadius, h);
    path.quadraticBezierTo(
      activeSlant,
      h,
      activeSlant - (activeObtuseRadius * activeSlant) / h,
      h - activeObtuseRadius,
    );
    path.lineTo((activeRadius * activeSlant) / h, activeRadius);
    path.quadraticBezierTo(0, 0, activeRadius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant SlantedCardClipper oldClipper) {
    return slantOffset != oldClipper.slantOffset ||
        radius != oldClipper.radius ||
        obtuseRadius != oldClipper.obtuseRadius;
  }
}
