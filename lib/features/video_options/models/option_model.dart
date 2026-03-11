import 'package:flutter/material.dart';

class OptionModel {
  final String title;
  final String icon;
  final Color? iconColor;
  final Color? textColor;
  final bool hasArrow;

  OptionModel({
    required this.title,
    required this.icon,
    this.iconColor,
    this.textColor,
    this.hasArrow = false,
  });
}
