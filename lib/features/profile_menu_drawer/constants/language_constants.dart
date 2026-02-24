import 'package:flutter/animation.dart';

import '../models/language_model.dart';

class LanguageConstants {
  static const List<LanguageModel> languages = [
    LanguageModel(code: 'en', nativeName: 'English', englishName: 'English'),
    LanguageModel(code: 'es', nativeName: 'Español', englishName: 'Spanish'),
    LanguageModel(code: 'fr', nativeName: 'Français', englishName: 'French'),
    LanguageModel(code: 'de', nativeName: 'Deutsch', englishName: 'German'),
    LanguageModel(code: 'it', nativeName: 'Italiano', englishName: 'Italian'),
    LanguageModel(
      code: 'pt',
      nativeName: 'Português',
      englishName: 'Portuguese',
    ),
    LanguageModel(code: 'ru', nativeName: 'Русский', englishName: 'Russian'),
    LanguageModel(code: 'ja', nativeName: '日本語', englishName: 'Japanese'),
    LanguageModel(code: 'ko', nativeName: '한국어', englishName: 'Korean'),
    LanguageModel(code: 'zh', nativeName: '中文', englishName: 'Chinese'),
    LanguageModel(code: 'ar', nativeName: 'العربية', englishName: 'Arabic'),
    LanguageModel(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
  ];

  static const Color backgroundColor = Color(0xFF4B005D);
  static const double tileOpacity = 0.5;
  static const double tileRadius = 15.0;
}
