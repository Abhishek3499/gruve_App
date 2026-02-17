import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String username;
  final String message;
  final String time;
  final String profileImage; // 👈 add
  final String? postImage; // 👈 optional thumbnail

  const NotificationTile({
    super.key,
    required this.username,
    required this.message,
    required this.time,
    required this.profileImage,
    this.postImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          /// 🔥 PROFILE IMAGE
          CircleAvatar(radius: 24, backgroundImage: AssetImage(profileImage)),

          const SizedBox(width: 12),

          /// 🔥 TEXT AREA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$username $message",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          /// 🔥 RIGHT THUMBNAIL (if exists)
          if (postImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 55,
                height: 55,
                child: Image.asset(postImage!, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}
