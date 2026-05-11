import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/conversation_model.dart';
import '../screen/chat_screen.dart';
import '../../../core/assets.dart';

class MessageCard extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;

  const MessageCard({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('💬 [MessageCard] Building card for: ${conversation.otherUserName}');
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigate to ChatScreen with conversation data
        debugPrint('🔗 [MessageCard] Tapped to open chat with: ${conversation.otherUserName}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userOrConversation: conversation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 08),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xA672008D),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Avatar
            _buildAvatar(),

            const SizedBox(width: 14),

            /// Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      /// Name + Message Area
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.otherUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conversation.lastMessageContent,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Time + Badge (Fixed Size)
                      SizedBox(
                        width: 75, // fixed width
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              conversation.lastMessageTimeAgo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),

                            SizedBox(
                              height: 22, // fixed height space
                              child: conversation.hasUnreadMessages
                                  ? Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF4D4F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        conversation.unreadCount > 99 
                                            ? '99+' 
                                            : conversation.unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(), // empty but space reserved
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build avatar widget with network image support and fallback
  Widget _buildAvatar() {
    final avatarUrl = conversation.otherUserAvatar;
    debugPrint('👤 [MessageCard] Building avatar for: ${conversation.otherUserName} - URL: $avatarUrl');
    
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: CachedNetworkImageProvider(
          avatarUrl,
        ),
        backgroundColor: Colors.grey[300],
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 20,
        ),
      );
    } else {
      // Fallback to asset image
      return CircleAvatar(
        radius: 30,
        backgroundImage: const AssetImage(AppAssets.profile),
      );
    }
  }
}
