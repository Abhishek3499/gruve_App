import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String username;
  final String message;
  final String time;
  final String profileImage;
  final String? postImage;

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(radius: 20, backgroundImage: AssetImage(profileImage)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$username $message",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (postImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Image.asset(postImage!, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}
