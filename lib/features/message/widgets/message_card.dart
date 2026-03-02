import 'package:flutter/material.dart';
import '../../../core/assets.dart';

class MessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String avatar;

  const MessageCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    this.avatar = AppAssets.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 05, vertical: 8),

      // padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFF72008D).withOpacity(0.65),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(radius: 24, backgroundImage: AssetImage(avatar)),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
