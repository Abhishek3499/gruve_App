import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';

/// Instagram-style chat list skeleton loader
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ChatItemSkeleton(),
    );
  }
}

/// Individual chat item skeleton
class _ChatItemSkeleton extends StatelessWidget {
  const _ChatItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Message content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and time skeleton
                Row(
                  children: [
                    // Username skeleton
                    Expanded(
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time skeleton
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Last message skeleton
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Unread indicator skeleton
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat conversation skeleton with optimized layout for smooth transitions
class ChatConversationSkeleton extends StatelessWidget {
  const ChatConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Match the ListView padding in chat screen for seamless transition
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Date separator skeleton - matches app styling
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Message skeletons with realistic spacing to prevent layout jumps
          // Using 5 messages to simulate realistic conversation loading
          ...List.generate(5, (index) => _MessageSkeleton(isOwn: index % 2 == 0)),
        ],
      ),
    );
  }
}

/// Individual message skeleton with optimized spacing to match real message bubbles
class _MessageSkeleton extends StatelessWidget {
  final bool isOwn;

  const _MessageSkeleton({required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Column(
      // Match the exact spacing from _buildMessageRow in chat_screen.dart
      children: [
        if (isOwn) const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                // Avatar skeleton for received message - matches real avatar size
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Message bubble skeleton with realistic proportions
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text skeleton with varying widths for realism
                      Container(
                        width: isOwn ? 120.0 : 180.0,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.shimmerHighlight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(height: 4),
                        // Read receipt skeleton - matches real read receipt positioning
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerHighlight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isOwn) const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chat input skeleton optimized to match actual ChatInputField design
class ChatInputSkeleton extends StatelessWidget {
  const ChatInputSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Match app's gradient background for seamless transition
        color: Colors.transparent,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.2)),
      ),
      child: Row(
        children: [
          // Camera button skeleton - matches actual camera button size
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          // Text input skeleton - matches actual input field dimensions
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button skeleton - matches actual send button size
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat refresh skeleton
class ChatRefreshSkeleton extends StatelessWidget {
  const ChatRefreshSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Shimmer wrapper for chat conversation skeleton with production-level UX
/// 
/// This wrapper provides Instagram-style shimmer loading effects for the chat screen
/// during initial message loading. It ensures smooth transitions and prevents layout jumps.
/// 
/// PERFORMANCE OPTIMIZATIONS:
/// - Uses const constructors to prevent unnecessary rebuilds
/// - Fixed shimmer period for consistent animation timing
/// - Optimized skeleton layout to match real message dimensions
/// - Pre-calculated widths and heights to avoid layout calculations
/// 
/// Usage: Show only during initial loading when messages list is empty
/// - DO show: isInitialLoading && messages.isEmpty
/// - DO NOT show: during pagination, realtime updates, socket updates, pull-to-refresh
/// 
/// INTEGRATION POINTS:
/// - ChatScreen._buildMessageBody() - replaces CircularProgressIndicator
/// - Uses AppColors.shimmerBase/shimmerHighlight for consistent theming
/// - Wraps ChatConversationSkeleton and ChatInputSkeleton for complete UI coverage
class ChatShimmerSkeleton extends StatelessWidget {
  const ChatShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Use app-specific shimmer colors for consistent theming across the app
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      // Optimized animation period: 1500ms matches WhatsApp/Instagram timing
      // Not too fast (distracting) and not too slow (feels sluggish)
      period: const Duration(milliseconds: 1500),
      // Performance: Use const child to prevent unnecessary rebuilds
      child: const Column(
        children: [
          // Message area skeleton - takes most of the screen space
          // Expanded ensures skeleton fills available space like real messages
          Expanded(
            child: ChatConversationSkeleton(),
          ),
          // Input area skeleton - fixed position at bottom like real input
          ChatInputSkeleton(),
        ],
      ),
    );
  }
}
