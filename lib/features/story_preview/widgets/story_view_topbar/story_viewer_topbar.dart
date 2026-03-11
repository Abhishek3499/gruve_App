import 'package:flutter/material.dart';

class StoryViewerTopBar extends StatelessWidget {
  final String username;
  final String time;
  final String avatarUrl;
  final int storyCount;
  final int currentIndex;
  final VoidCallback onClose;

  const StoryViewerTopBar({
    super.key,
    required this.username,
    required this.time,
    required this.avatarUrl,
    required this.storyCount,
    required this.currentIndex,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STORY PROGRESS BARS
            Row(
              children: List.generate(storyCount, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      color: index <= currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            /// USER INFO ROW
            Row(
              children: [
                /// AVATAR
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(avatarUrl),
                ),

                const SizedBox(width: 8),

                /// USERNAME
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 6),

                /// TIME
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                /// CLOSE BUTTON
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.white, size: 26),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
