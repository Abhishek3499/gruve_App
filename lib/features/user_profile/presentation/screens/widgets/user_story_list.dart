import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class UserStoryList extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final bool isLoading;

  const UserStoryList({
    super.key,
    required this.stories,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show skeleton placeholders when loading or no stories
    if (isLoading || stories.isEmpty) {
      return SizedBox(
        height: 90,
        child: Row(
          children: [
            /// 🔥 SCROLLABLE STORIES (skeleton placeholders)
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6, // Show 6 skeleton placeholders
                itemBuilder: (context, index) => _buildStorySkeleton(),
              ),
            ),
          ],
        ),
      );
    }

    // Show real stories
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          /// 🔥 SCROLLABLE STORIES
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return _buildStory(
                  story['mediaUrl'] ?? '',
                  story['id']?.toString() ?? 'Story ${index + 1}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 STORY WITH GRADIENT BORDER
  Widget _buildStory(String imageUrl, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
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
              backgroundImage: imageUrl.isNotEmpty 
                  ? NetworkImage(imageUrl)
                  : null,
              backgroundColor: const Color(0xFF212235),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.image_outlined, color: Colors.white70)
                  : null,
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

  /// 🔥 STORY SKELETON FOR SHIMMER EFFECT
  Widget _buildStorySkeleton() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
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
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF212235),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF212235),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
