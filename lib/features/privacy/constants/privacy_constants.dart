import 'package:flutter/material.dart';
import 'package:gruve_app/features/privacy/domain/entities/privacy_option_model.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class PrivacyConstants {
  static const List<PrivacyOptionModel> privacyOptions = [
    PrivacyOptionModel(
      title: 'Private Account',
      description:
          'When your account is private, only people you approve can follow you and see your posts, videos, and activity. Your existing followers won\'t be affected.',
      cardDescription:
          'Only people you approve can follow you and see your posts, videos, and activity.',
      isEnabled: true,
    ),
  ];

  // Page-level heading (outside the card)

  static const TextStyle sectionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle sectionDescriptionStyle = TextStyle(
    color: AppColors.white70,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Card row (title + description next to the toggle)

  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: AppColors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  // 👇 Baaki gradients niche hi rahenge

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9544A7), AppColors.deepPlum],
  );

  /// Flat, mostly-solid purple card — matches the reference's plain panel
  /// rather than a glassy multi-tone gradient.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D1550), Color(0xFF34124A)],
  );

  static const double cardBorderRadius = 24.0;
  static const Color cardBorderColor = Color(0x14FFFFFF);
  static const Color shadowColor = Color(0xFF1A0A1F);

  static const Color iconBadgeBg = Color(0xFF56206B);
  static const double iconBadgeSize = 50.0;
  static const double iconBadgeRadius = 16.0;
}
