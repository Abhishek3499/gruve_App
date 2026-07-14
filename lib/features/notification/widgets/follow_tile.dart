import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/widgets/cached_avatar.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';
import '../../message/utils/conversation_utils.dart';

class FollowTile extends StatelessWidget {
  final String username;
  final String time;
  final String profileImage;
  final String userId;
  final bool isRead;
  final VoidCallback? onTap;

  const FollowTile({
    super.key,
    required this.username,
    required this.time,
    required this.profileImage,
    required this.userId,
    this.isRead = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 24, 8),
        child: Row(
          children: [
            // Unread dot indicator
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFC06CFF),
                  shape: BoxShape.circle,
                ),
              ),
            GestureDetector(
              onTap: () {
                if (userId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        profileUserId: userId,
                        userName: username,
                        profileImageUrl: profileImage.isNotEmpty ? profileImage : null,
                      ),
                    ),
                  );
                }
              },
              child: CachedAvatar(
                imageUrl: profileImage,
                username: username,
                radius: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$username started following you.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isRead ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      color: isRead ? Colors.white60 : Colors.white70,
                      fontSize: 11,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                    ),
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
              onPressed: () {
                if (onTap != null) onTap!();
                _handleMessageTap(context);
              },
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
