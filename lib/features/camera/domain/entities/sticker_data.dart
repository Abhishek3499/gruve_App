import 'package:flutter/material.dart';

class StickerData {
  final String id;
  final String text;
  Offset position;
  double scale;
  double rotation;

  // Text formatting properties
  final bool isText;
  final Color textColor;
  final Color backgroundColor;
  final String fontFamily;
  final bool hasBackground;
  final TextAlign textAlign;

  // Music properties
  final bool isMusic;
  final String? musicTitle;
  final String? musicArtist;
  final double? musicTrimStart;
  final double? musicTrimDuration;

  StickerData({
    required this.id,
    required this.text,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isText = false,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.fontFamily = 'Raleway',
    this.hasBackground = false,
    this.textAlign = TextAlign.center,
    this.isMusic = false,
    this.musicTitle,
    this.musicArtist,
    this.musicTrimStart,
    this.musicTrimDuration,
  });

  StickerData copyWith({
    String? id,
    String? text,
    Offset? position,
    double? scale,
    double? rotation,
    bool? isText,
    Color? textColor,
    Color? backgroundColor,
    String? fontFamily,
    bool? hasBackground,
    TextAlign? textAlign,
    bool? isMusic,
    String? musicTitle,
    String? musicArtist,
    double? musicTrimStart,
    double? musicTrimDuration,
  }) {
    return StickerData(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isText: isText ?? this.isText,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      hasBackground: hasBackground ?? this.hasBackground,
      textAlign: textAlign ?? this.textAlign,
      isMusic: isMusic ?? this.isMusic,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      musicTrimStart: musicTrimStart ?? this.musicTrimStart,
      musicTrimDuration: musicTrimDuration ?? this.musicTrimDuration,
    );
  }
}
