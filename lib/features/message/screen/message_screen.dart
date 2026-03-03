import 'package:flutter/material.dart';
import '../widgets/message_header.dart';
import '../widgets/message_card.dart';

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
                      children: const [
                        MessageCard(
                          title: 'Emma Watson',
                          message: 'Did you check the design updates?',
                          time: '5 min ago',
                          unreadCount: 2,
                        ),

                        MessageCard(
                          title: 'Michael Carter',
                          message: 'Let’s catch up in the evening.',
                          time: '12 min ago',
                          unreadCount: 1,
                        ),

                        MessageCard(
                          title: 'Sophia Williams',
                          message: 'I have shared the documents.',
                          time: '25 min ago',
                          unreadCount: 4,
                        ),

                        MessageCard(
                          title: 'Daniel Brown',
                          message: 'Call me when you’re free.',
                          time: '40 min ago',
                          unreadCount: 0,
                        ),

                        MessageCard(
                          title: 'Olivia Johnson',
                          message: 'Meeting is confirmed for tomorrow.',
                          time: '1 hr ago',
                          unreadCount: 3,
                        ),

                        MessageCard(
                          title: 'James Anderson',
                          message: 'Thanks for your quick response!',
                          time: '2 hr ago',
                          unreadCount: 0,
                        ),

                        MessageCard(
                          title: 'Ava Martinez',
                          message: 'Can you review the latest build?',
                          time: '3 hr ago',
                          unreadCount: 5,
                        ),

                        MessageCard(
                          title: 'William Taylor',
                          message: 'Everything looks perfect 👍',
                          time: 'Yesterday',
                          unreadCount: 0,
                        ),

                        MessageCard(
                          title: 'Isabella Thomas',
                          message: 'Please send me the invoice.',
                          time: 'Yesterday',
                          unreadCount: 2,
                        ),

                        MessageCard(
                          title: 'Ethan Harris',
                          message: 'Let’s finalize the deal today.',
                          time: '2 days ago',
                          unreadCount: 1,
                        ),
                      ],
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
