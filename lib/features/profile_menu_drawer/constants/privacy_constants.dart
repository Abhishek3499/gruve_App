import 'package:flutter/material.dart';
import '../models/privacy_option_model.dart';

class PrivacyConstants {
  static const List<PrivacyOptionModel> privacyOptions = [
    PrivacyOptionModel(
      title: 'Private Account',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      isEnabled: true,
    ),
    PrivacyOptionModel(
      title: 'Allow public videos to appear in search engine results',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      isEnabled: false,
    ),
  ];

  // 👇 YAHAN ADD KARNA HAI (Text Styles)

  static const TextStyle titleStyle = TextStyle(
    color: Color(0xFFF5CDFF),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: Color(0xFFF5CDFF),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // 👇 Baaki gradients niche hi rahenge

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9544A7), Color(0xFF42174C)],
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
