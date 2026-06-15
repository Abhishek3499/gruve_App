import 'package:flutter/material.dart';

class StickerData {
  final String id;
  final String text;
  Offset position;
  double scale;
  double rotation;

  StickerData({
    required this.id,
    required this.text,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  StickerData copyWith({
    String? id,
    String? text,
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return StickerData(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}
