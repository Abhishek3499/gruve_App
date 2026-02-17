import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/assets.dart';

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          buildStory("+"),
          buildStory(AppAssets.frame1),
          buildStory(AppAssets.frame2),
          buildStory(AppAssets.frame3),
        ],
      ),
    );
  }

  Widget buildStory(String data) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.white24,
        backgroundImage: data.contains(".jpg") || data.contains(".png")
            ? AssetImage(data)
            : null,
        child: data == "+"
            ? const Icon(Icons.add, color: Colors.white)
            : null,
      ),
    );
  }
}
