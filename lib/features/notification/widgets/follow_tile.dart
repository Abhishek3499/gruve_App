import 'package:flutter/material.dart';
import '../../message/utils/conversation_utils.dart';

class FollowTile extends StatelessWidget {
  final String username;
  final String time;
  final String profileImage;
  final String userId;

  const FollowTile({
    super.key,
    required this.username,
    required this.time,
    required this.profileImage,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: AssetImage(profileImage)),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$username started following you.",
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

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _handleMessageTap(context),
            child: const Text("Message", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleMessageTap(BuildContext context) {
    ConversationUtils.navigateToChat(
      context: context,
      receiverId: userId,
      receiverName: username,
      receiverProfileImage: profileImage.isNotEmpty ? profileImage : null,
      source: 'follow_tile',
    );
  }
}
