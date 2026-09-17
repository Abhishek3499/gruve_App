import 'package:flutter/material.dart';

/// Reusable progress bar widget
class InteractionsProgressBar extends StatelessWidget {
  final String label;
  final double percentage;

  const InteractionsProgressBar({
    super.key,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final followersPart = percentage * 0.45; // pink part
    final nonFollowersPart = percentage * 0.45; // purple part
    final remainingPart = 100 - percentage; // white part

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                // Pink Segment
                Expanded(
                  flex: followersPart.round(),
                  child: Container(color: const Color(0xFFFF3AFF)),
                ),

                // 🔥 WHITE DIVIDER
                Container(
                  width: 3, // divider thickness
                  color: Colors.white,
                ),

                // Purple Segment
                Expanded(
                  flex: nonFollowersPart.round(),
                  child: Container(color: const Color(0xFF72008D)),
                ),

                // Remaining White
                Expanded(
                  flex: remainingPart.round(),
                  child: Container(color: Colors.white.withAlpha(200)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
