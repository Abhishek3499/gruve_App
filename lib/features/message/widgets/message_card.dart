import 'package:flutter/material.dart';
import '../../../core/assets.dart';
import '../models/message_model.dart';
import '../screen/chat_screen.dart';

class MessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String avatar;
  final int unreadCount;

  const MessageCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    this.avatar = AppAssets.profile,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Create ChatUser from MessageCard data
        final chatUser = ChatUser(
          id: title.hashCode.toString(), // Generate unique ID from title
          name: title,
          avatar: avatar,
          lastMessage: message,
          lastMessageTime: time,
          unreadCount: unreadCount,
        );

        // Navigate to ChatScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(user: chatUser)),
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
            CircleAvatar(radius: 30, backgroundImage: AssetImage(avatar)),

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
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
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
                              time,
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
                              child: unreadCount > 0
                                  ? Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF4D4F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
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
}
