import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/close_friend_Screen.dart';
import 'package:gruve_app/features/story_preview/screens/hide_story_screen.dart';

class ViewCard extends StatelessWidget {
  const ViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF72008D), Color(0xFF511263)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2E1735),
            offset: Offset(-10, -10),
            blurRadius: 19,
          ),
          BoxShadow(
            color: Color(0xFF2E1735),
            offset: Offset(10, 10),
            blurRadius: 19,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Viewing",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          /// HIDE STORY
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HideStoryScreen()),
              );
            },
            child: _buildItem(
              title: "Hide Story from",
              subtitle: "Hide your story from specific people",
              people: "0 people",
            ),
          ),

          const SizedBox(height: 25),

          /// CLOSE FRIENDS
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloseFriendScreen()),
              );
            },
            child: _buildItem(
              // FIXED HERE
              title: "Close friends",
              subtitle: "Share your story with specific people",
              people: "3 people",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required String subtitle,
    required String people,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),

        /// PEOPLE + ARROW
        Row(
          children: [
            Text(
              people,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ],
    );
  }
}
