import 'package:flutter/material.dart';
import 'app_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommentShimmer — skeleton for the comments bottom sheet.
//
// WHY THIS MATTERS:
//   Currently the comment sheet shows a CircularProgressIndicator while
//   fetching. This skeleton shows the exact shape of comment rows so the
//   user knows what's loading. It also prevents layout shift when real
//   comments appear — the height is consistent.
//
// LAYOUT MIRRORS:
//   Each row = avatar circle + (username line + comment text lines)
//   Matches _buildCommentTile() in comment_sheet.dart exactly.
// ─────────────────────────────────────────────────────────────────────────────
class CommentShimmer extends StatelessWidget {
  final int itemCount;

  const CommentShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: itemCount,
        itemBuilder: (_, index) => _CommentSkeletonRow(
          // Vary line widths so it looks natural, not robotic
          captionWidth: index.isEven ? 220.0 : 180.0,
        ),
      ),
    );
  }
}

class _CommentSkeletonRow extends StatelessWidget {
  final double captionWidth;

  const _CommentSkeletonRow({required this.captionWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const ShimmerCircle(radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + timestamp row
                Row(
                  children: const [
                    ShimmerBox(width: 90, height: 12, borderRadius: 5),
                    SizedBox(width: 8),
                    ShimmerBox(width: 30, height: 10, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 7),
                // Comment text line 1
                ShimmerBox(
                  width: double.infinity,
                  height: 13,
                  borderRadius: 5,
                ),
                const SizedBox(height: 5),
                // Comment text line 2 (shorter)
                ShimmerBox(width: captionWidth, height: 13, borderRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
