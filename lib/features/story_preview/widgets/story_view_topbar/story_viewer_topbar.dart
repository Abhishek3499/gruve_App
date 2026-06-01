import 'package:flutter/material.dart';

class StoryViewerTopBar extends StatelessWidget {
  final String username;
  final String time;
  final String avatarUrl;
  final int storyCount;
  final int currentIndex;
  final VoidCallback onClose;
  final double progress;

  const StoryViewerTopBar({
    super.key,
    required this.username,
    required this.time,
    required this.avatarUrl,
    required this.storyCount,
    required this.currentIndex,
    required this.onClose,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InstagramStoryProgress(
              storyCount: storyCount,
              currentIndex: currentIndex,
              progress: progress,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(avatarUrl),
                ),

                const SizedBox(width: 8),

                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 6),

                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

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

class _InstagramStoryProgress extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final double progress;

  const _InstagramStoryProgress({
    required this.storyCount,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final count = storyCount <= 0 ? 1 : storyCount;

    return Row(
      children: List.generate(count, (index) {
        final fill = index < currentIndex
            ? 1.0
            : index == currentIndex
            ? progress.clamp(0.0, 1.0)
            : 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 2,
              right: index == count - 1 ? 0 : 2,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 2.6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
