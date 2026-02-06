import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String highlightedText;

  const AuthHeader({super.key, required this.title, this.highlightedText = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔥 Logo
        Image.asset(AppAssets.logoMain, width: 90),

        const SizedBox(height: 30),

        // 🔥 Title with highlight
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
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
