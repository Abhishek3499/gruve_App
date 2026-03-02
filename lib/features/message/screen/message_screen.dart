import 'package:flutter/material.dart';
import '../widgets/message_header.dart';
import '../widgets/message_card.dart';
import '../widgets/message_footer.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14001A),
      body: Column(
        children: [
          /// ===== HEADER =====
          const MessageHeader(),

          /// ===== MESSAGE CARDS =====
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                MessageCard(
                  title: 'John Doe',
                  message: 'Hey, how are you doing?',
                  time: '2:30 PM',
                ),
                MessageCard(
                  title: 'Jane Smith',
                  message: 'Can we schedule a meeting?',
                  time: '1:15 PM',
                ),
                MessageCard(
                  title: 'Support Team',
                  message: 'Your issue has been resolved',
                  time: '11:45 AM',
                ),
                MessageCard(
                  title: 'Mike Johnson',
                  message: 'Thanks for your help!',
                  time: 'Yesterday',
                ),
              ],
            ),
          ),

          /// ===== FOOTER =====
          const MessageFooter(),
        ],
      ),
    );
  }
}
