import 'package:flutter/material.dart';

class SlantedCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double slantOffset = 25.0;
    const double radius = 12.0;
    const double obtuseRadius = 20.0;
    final double w = size.width;
    final double h = size.height;

    // Dynamically scale the slant and radii down if the height is small (e.g. thin placeholder bars)
    // to prevent overlap, negative bounds, or reversed slant directions.
    final double activeSlant = (h < 90.0) ? (slantOffset * h / 90.0) : slantOffset;
    final double activeRadius = (h < 90.0) ? (radius * h / 90.0) : radius;
    final double activeObtuseRadius = (h < 90.0) ? (obtuseRadius * h / 90.0) : obtuseRadius;

    // Start on the top edge, just after the top-left rounded corner curve (acute corner)
    path.moveTo(activeRadius, 0);
    
    // Line to the top-right corner before the curve (90 degree corner)
    path.lineTo(w - activeRadius, 0);
    
    // Curve around top-right corner to the right vertical edge
    path.quadraticBezierTo(w, 0, w, activeRadius);
    
    // Line down the right vertical edge to before the bottom-right curve (90 degree corner)
    path.lineTo(w, h - activeRadius);
    
    // Curve around bottom-right corner to the bottom edge
    path.quadraticBezierTo(w, h, w - activeRadius, h);
    
    // Line along the bottom edge to before the bottom-left curve (obtuse corner)
    path.lineTo(activeSlant + activeObtuseRadius, h);
    
    // Curve around bottom-left corner to the left slanted edge
    path.quadraticBezierTo(
      activeSlant,
      h,
      activeSlant - (activeObtuseRadius * activeSlant) / h,
      h - activeObtuseRadius,
    );
    
    // Line up the left slanted edge to before the top-left curve (acute corner)
    path.lineTo((activeRadius * activeSlant) / h, activeRadius);
    
    // Curve around top-left corner
    path.quadraticBezierTo(0, 0, activeRadius, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    // Return false if the shape doesn't need to change dynamically
    return false;
  }
}
