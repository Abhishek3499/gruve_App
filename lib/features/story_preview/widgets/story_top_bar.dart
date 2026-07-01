import 'package:flutter/material.dart';

class StoryTopBar extends StatelessWidget {
  final VoidCallback onClose;

  const StoryTopBar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Row(
          children: [
            BackButton(
              color: Colors.white,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
