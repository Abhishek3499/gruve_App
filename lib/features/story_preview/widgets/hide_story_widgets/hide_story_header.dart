import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class HideStoryHeader extends StatelessWidget {
  final VoidCallback onBack;

  const HideStoryHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,

      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// BACK BUTTON
            Positioned(
              left: 20,
              child: GestureDetector(
                onTap: onBack,
                child: Image.asset(AppAssets.back, width: 24),
              ),
            ),

            /// TITLE
            const Text(
              "Hide story from",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w200,
                fontFamily: "syncopate",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
