import 'package:flutter/material.dart';
import 'package:gruve_app/features/privacy/domain/entities/privacy_option_model.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class PrivacyConstants {
  static const List<PrivacyOptionModel> privacyOptions = [
    PrivacyOptionModel(
      title: 'Private Account',
      description:
          'When your account is private, only people you approve can follow you and see your posts, videos, and activity. Your existing followers won\'t be affected.',
      isEnabled: true,
    ),
  ];

  //

  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // 👇 Baaki gradients niche hi rahenge

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9544A7), AppColors.deepPlum],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF72008D), Color(0xFF511263)],
  );

  static const double cardBorderRadius = 10.0;
  static const Color shadowColor = Color(0xFF2E1735);
  static const double shadowBlur = 19.0;
  static const Offset shadowOffset1 = Offset(-10, -10);
  static const Offset shadowOffset2 = Offset(10, 10);
}
