import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/post/more_model.dart';

class MoreConstants {
  static const List<MoreModel> sharingPreferences = [
    MoreModel(
      title: 'Schedule this reel',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      isEnabled: false,
      icon: 'assets/icons/schedule.png', // ⏱ icon
    ),
    MoreModel(
      title: 'Upload at highest quality',
      description:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      isEnabled: false,
      icon: 'assets/icons/high_quality.png', // ⬆ icon
    ),
  ];

  /// 👥 Interaction Controls (SS MATCH)
  static const List<MoreModel> interactionOptions = [
    MoreModel(
      title: 'Hide like count on this reel',
      description: '',
      isEnabled: false,
      icon: 'assets/icons/hide_like.png', // 🚫❤️
    ),
    MoreModel(
      title: 'Hide share count on this reel',
      description: '',
      isEnabled: false,
      icon: 'assets/icons/hide_share.png', // 🚫🔁
    ),
  ];

  /// 🧠 SECTION MAP (IMPORTANT FOR UI LIKE SS)
  static const Map<String, List<MoreModel>> sections = {
    "Sharing preferences": sharingPreferences,
    "How others can interact with your reel": interactionOptions,
  };

  // 🎨 TEXT STYLES
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

  static const TextStyle sectionTitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // 🎨 GRADIENTS
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
