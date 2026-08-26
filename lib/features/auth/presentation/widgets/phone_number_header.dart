import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class PhoneNumberHeader extends StatelessWidget {
  final String title;
  final String highlightedText;

  const PhoneNumberHeader({
    super.key,
    required this.title,
    this.highlightedText = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔥 Logo

        // 🔥 Title with highlight
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: AppAssets.syncopateFont,
            ),
            children: [
              TextSpan(text: title),
              if (highlightedText.isNotEmpty)
                TextSpan(
                  text: highlightedText,
                  style: const TextStyle(
                    color: Color(0xFFB86AD0),
                    fontFamily: AppAssets.syncopateFont,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
