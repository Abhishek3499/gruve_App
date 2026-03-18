import 'package:flutter/material.dart';
import '../constants/language_constants.dart';
import '../models/language_model.dart';

class LanguageTile extends StatelessWidget {
  final LanguageModel language;
  final VoidCallback onTap;

  const LanguageTile({super.key, required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LanguageConstants.backgroundColor.withValues(
            alpha: LanguageConstants.tileOpacity,
          ),
          borderRadius: BorderRadius.circular(LanguageConstants.tileRadius),
        ),
        child: Row(
          children: [
            // Language Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    language.englishName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Arrow Icon
          ],
        ),
      ),
    );
  }
}
