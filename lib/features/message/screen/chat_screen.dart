import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../data/dummy_messages.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    // In a real app, this would fetch from an API
    setState(() {
      _messages = DummyMessages.getChatMessages(widget.user.id);
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
    );

    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
    });

    // Simulate sending delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      body: SafeArea(
        child: Column(
          children: [
            /// Chat Header
            ChatHeader(user: widget.user, onBack: () => Navigator.pop(context)),

            /// Chat Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(message: message);
                },
              ),
            ),

            /// Chat Input Field
            ChatInputField(onSendMessage: _sendMessage, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}
