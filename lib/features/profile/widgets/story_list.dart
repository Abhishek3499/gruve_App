import 'package:flutter/material.dart';
import '../../../core/assets.dart';

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          /// 🔥 FIXED + BUTTON (NOT SCROLLABLE)
          const SizedBox(width: 30),
          _buildAddStory(),
          const SizedBox(width: 18),

          /// 🔥 SCROLLABLE STORIES
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStory(AppAssets.frame1, "Image 1"),
                _buildStory(AppAssets.frame2, "Image 2"),
                _buildStory(AppAssets.frame3, "Image 3"),
                _buildStory(AppAssets.frame2, "Image 4"),
                _buildStory(AppAssets.frame3, "Image 5"),
                _buildStory(AppAssets.frame2, "Image 6"),
                _buildStory(AppAssets.frame1, "Image 7"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 ADD STORY (STATIC)
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

  /// 🔥 STORY WITH GRADIENT BORDER
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
              radius: 30,
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
