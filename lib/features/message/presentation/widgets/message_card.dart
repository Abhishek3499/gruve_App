import 'package:flutter/material.dart';
import 'package:gruve_app/core/services/socket_service.dart';

import 'package:gruve_app/shared/widgets/optimized/optimized_image.dart';
import 'package:gruve_app/features/message/domain/entities/conversation_model.dart';
import 'package:gruve_app/features/message/utils/shared_post_message_parser.dart';
import 'package:gruve_app/features/message/utils/user_display_helper.dart';

class MessageCard extends StatelessWidget {
  final SocketService _socketService = SocketService();
  final ConversationModel conversation;
  final VoidCallback? onTap;

  MessageCard({super.key, required this.conversation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xA672008D),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserDisplayHelper.getDisplayNameForConversation(
                            conversation,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (conversation.lastMessage.messageKind ==
                                'audio') ...[
                              const Icon(
                                Icons.mic,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                SharedPostMessageParser.conversationPreview(
                                  conversation.lastMessageContent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 10),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 100),
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
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 20,
                            child: conversation.hasUnreadMessages
                                ? Container(
                                    width: 20,
                                    height: 20,
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
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final userId = conversation.otherUser.id;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: _socketService.onlineUsers,
      builder: (context, onlineUsers, _) {
        final isOnline = onlineUsers.contains(userId);

        return Stack(
          children: [
            OptimizedAvatar(
              imageUrl: UserDisplayHelper.getProfileImageForUser(conversation),

              name: UserDisplayHelper.getDisplayNameForConversation(
                conversation,
              ),

              radius: 26,
            ),

            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
