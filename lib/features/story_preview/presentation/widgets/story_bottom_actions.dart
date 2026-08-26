import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class StoryViewBottom extends StatelessWidget {
  const StoryViewBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 70,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3), // 👈 glass bg
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.favorite_border, color: Colors.white),
                  SizedBox(height: 4),
                  Text("Highlight", style: TextStyle(color: Colors.white)),
                ],
              ),

              const SizedBox(width: 30),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.more_horiz, color: Colors.white),
                  SizedBox(height: 4),
                  Text("More", style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
