import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/screens/more_screen.dart';

class StoryViewBottom extends StatelessWidget {
  const StoryViewBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // 👈 right side
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.hightlight,
                width: 24,
                height: 24,
                color: Colors.white, // optional agar icon white chahiye
              ),
              SizedBox(height: 4),
              Text("Highlight", style: TextStyle(color: Colors.white)),
            ],
          ),

          const SizedBox(width: 30),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoreScreen()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.more_horiz, color: Colors.white),
                SizedBox(height: 4),
                Text("More", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
