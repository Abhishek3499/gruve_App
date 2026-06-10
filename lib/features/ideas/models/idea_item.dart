import 'package:flutter/material.dart';

class IdeaItem {
  final String? imageUrl;
  final String? label;
  final double aspectRatio;
  final Color? solidColor;

  const IdeaItem({
    this.imageUrl,
    this.label,
    required this.aspectRatio,
    this.solidColor,
  });
}
