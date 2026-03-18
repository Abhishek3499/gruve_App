import 'package:flutter/material.dart';
import '../../../core/assets.dart';

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100, // Thodi height badhayi taaki text niche se cut na ho
      child: ListView(
        scrollDirection: Axis.horizontal,
        // Left side se thodi spacing jaisa pehle SizedBox(width: 30) se thi
        padding: const EdgeInsets.only(left: 30),
        children: [
          /// 🔥 AB YE BHI SCROLL HOGA (List ke andar aa gaya)
          _buildAddStory(),

          /// 🔥 BAAKI STORIES
          _buildStory(AppAssets.frame1, "Admin..."),
          _buildStory(AppAssets.frame2, "Admin..."),
          _buildStory(AppAssets.frame3, "Admin..."),
          _buildStory(AppAssets.frame2, "Admin..."),
          _buildStory(AppAssets.frame3, "Admin..."),
          _buildStory(AppAssets.frame2, "Admin..."),
          _buildStory(AppAssets.frame1, "Admin..."),
        ],
      ),
    );
  }

  /// 🔥 ADD STORY (UI SAME HAI)
  Widget _buildAddStory() {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF212235),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Add Story",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 🔥 STORIES (UI SAME HAI)
  Widget _buildStory(String imagePath, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
              ),
            ),
            child: CircleAvatar(
              radius: 28, // Thoda adjust kiya taaki border ke sath set rahe
              backgroundImage: AssetImage(imagePath),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
