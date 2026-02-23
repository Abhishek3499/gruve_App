import 'package:flutter/material.dart';

import '../models/views_model.dart';

/// Followers stats row widget
class ViewsFollowersStats extends StatelessWidget {
  final bool isLeft;

  const ViewsFollowersStats({super.key, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final percentage = isLeft
        ? '${ViewsModel.data.followersPercentage.toStringAsFixed(1)}%'
        : '${ViewsModel.data.nonFollowersPercentage.toStringAsFixed(1)}%';

    final label = isLeft ? 'Followers' : 'Non-followers';

    final dotColor = isLeft ? const Color(0xFFFF3AFF) : const Color(0xFFFF3AFF);

    return Column(
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        /// Percentage
        Text(
          percentage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        /// Label + Dot (ALWAYS RIGHT SIDE)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 12,
                fontWeight: FontWeight(400),
              ),
            ),

            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
