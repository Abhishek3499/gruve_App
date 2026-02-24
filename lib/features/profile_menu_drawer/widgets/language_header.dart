import 'package:flutter/material.dart';
import '../../../core/assets.dart';

class LanguageHeader extends StatelessWidget {
  const LanguageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                AppAssets.back,
                width: 25,
                height: 25,
              ),
            ),
          ),

          // Title
          const Text(
            "Language",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'syncopate',
            ),
          ),
        ],
      ),
    );
  }
}
