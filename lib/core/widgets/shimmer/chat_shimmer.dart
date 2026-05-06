import 'package:flutter/material.dart';
import 'app_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatListShimmer — skeleton for the message/chat list screen.
//
// LAYOUT MIRRORS:
//   Each row = avatar + (name line + last message line) + timestamp
//   Matches MessageCard widget layout in message_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────
class ChatListShimmer extends StatelessWidget {
  final int itemCount;

  const ChatListShimmer({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemCount,
        itemBuilder: (_, index) => _ChatRowSkeleton(
          nameWidth: index % 3 == 0 ? 140.0 : (index % 3 == 1 ? 100.0 : 120.0),
          messageWidth: index.isEven ? 200.0 : 160.0,
        ),
      ),
    );
  }
}

class _ChatRowSkeleton extends StatelessWidget {
  final double nameWidth;
  final double messageWidth;

  const _ChatRowSkeleton({
    required this.nameWidth,
    required this.messageWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          const ShimmerCircle(radius: 26),
          const SizedBox(width: 14),
          // Name + last message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: nameWidth, height: 13, borderRadius: 5),
                const SizedBox(height: 7),
                ShimmerBox(width: messageWidth, height: 11, borderRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Timestamp
          const ShimmerBox(width: 32, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatBubbleShimmer — skeleton for inside a chat conversation while
// loading message history. Shows alternating sent/received bubbles.
// ─────────────────────────────────────────────────────────────────────────────
class ChatBubbleShimmer extends StatelessWidget {
  final int itemCount;

  const ChatBubbleShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: itemCount,
        itemBuilder: (_, index) {
          // Alternate between sent (right) and received (left)
          final isSent = index % 3 != 0;
          return _BubbleSkeleton(
            isSent: isSent,
            width: 120.0 + (index % 4) * 30.0,
          );
        },
      ),
    );
  }
}

class _BubbleSkeleton extends StatelessWidget {
  final bool isSent;
  final double width;

  const _BubbleSkeleton({required this.isSent, required this.width});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSent) ...[
            const ShimmerCircle(radius: 16),
            const SizedBox(width: 8),
          ],
          ShimmerBox(width: width, height: 38, borderRadius: 16),
        ],
      ),
    );
  }
}
