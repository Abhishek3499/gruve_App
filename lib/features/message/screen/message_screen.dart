import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../widgets/message_header.dart';
import '../widgets/message_card.dart';
import '../widgets/swipe_delete_background.dart';
import '../data/dummy_messages.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<ChatUser> _chatUsers = [];

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  void _loadChatUsers() {
    setState(() {
      _chatUsers = DummyMessages.getChatUsers();
    });
  }

  void _showDeleteConfirmation(ChatUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B36),
        title: const Text(
          'Delete Conversation',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete conversation with ${user.name}?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF72008D), fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(user);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF51829), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteConversation(ChatUser user) {
    setState(() {
      _chatUsers.removeWhere((chatUser) => chatUser.id == user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          /// 🔥 HEADER + LIST OVERLAP AREA
          Expanded(
            child: Stack(
              children: [
                /// HEADER
                const MessageHeader(),

                /// MESSAGE LIST
                Positioned(
                  top: 265,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C0B21),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatUsers.length,
                      itemBuilder: (context, index) {
                        final user = _chatUsers[index];
                        return Dismissible(
                          key: Key(user.id),
                          direction: DismissDirection.endToStart,
                          background: SwipeDeleteBackground(
                            onDelete: () => _showDeleteConfirmation(user),
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              _showDeleteConfirmation(user);
                            }
                          },
                          child: MessageCard(
                            title: user.name,
                            message: user.lastMessage,
                            time: user.lastMessageTime,
                            unreadCount: user.unreadCount,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 FOOTER (original wala hi)
        ],
      ),
    );
  }
}
