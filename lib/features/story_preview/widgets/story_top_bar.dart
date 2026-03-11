import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class StoryTopBar extends StatelessWidget {
  final VoidCallback onClose;

  const StoryTopBar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
        child: Row(
          children: [
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.6,
                  ), // background color
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  AppAssets.back,
                  color: Colors.white,
                  height: 20,
                  width: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
