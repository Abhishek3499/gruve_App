import 'package:flutter/material.dart';

class SlantedCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Move to the top-left corner (0, 0)
    path.moveTo(0, 0);
    // Draw line to the top-right corner
    path.lineTo(size.width, 0);
    // Draw line to a point slightly above the bottom-right corner (creating the slant)
    // Here, we move up by 30 units (adjust as needed)
    path.lineTo(size.width, size.height);
    // Draw line to the bottom-left corner
    path.lineTo(0, size.height);
    // Close the path (draws a line back to the start)
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    // Return false if the shape doesn't need to change dynamically
    return false;
  }
}
