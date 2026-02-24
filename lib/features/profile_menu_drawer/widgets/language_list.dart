import 'package:flutter/material.dart';
import '../constants/language_constants.dart';
import '../models/language_model.dart';
import 'language_tile.dart';

class LanguageList extends StatelessWidget {
  const LanguageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: LanguageConstants.languages.length,
        itemBuilder: (context, index) {
          final language = LanguageConstants.languages[index];
          return LanguageTile(
            language: language,
            onTap: () {
              // Handle language selection
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
