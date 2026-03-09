import 'package:flutter/material.dart';
import '../widgets/message_header.dart';
import '../widgets/message_card.dart';
import '../data/dummy_messages.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

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
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: DummyMessages.getChatUsers().map((user) => 
                        MessageCard(
                          title: user.name,
                          message: user.lastMessage,
                          time: user.lastMessageTime,
                          unreadCount: user.unreadCount,
                        ),
                      ).toList(),
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
