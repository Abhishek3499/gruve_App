import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';

class StoryList extends StatelessWidget {
  final UserModel user;

  const StoryList({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: user.stories.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add story button
            return buildStory("+");
          } else {
            // User story
            return buildStory(user.stories[index - 1]);
          }
        },
      ),
    );
  }

  Widget buildStory(String data) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.white24,
        backgroundImage: (data.contains(".jpg") || data.contains(".png"))
            ? AssetImage(data)
            : null,
        child: data == "+" ? const Icon(Icons.add, color: Colors.white) : null,
      ),
    );
  }
}
