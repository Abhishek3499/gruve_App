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
      padding: const EdgeInsets.fromLTRB(22, 8, 24, 8),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundImage: AssetImage(profileImage)),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$username started following you.",
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

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(76, 32),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: const BorderSide(color: Color(0xFF2B2B2B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => _handleMessageTap(context),
            child: const Text(
              "Message",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
