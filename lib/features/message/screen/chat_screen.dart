import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/reply_message_model.dart';
import '../data/dummy_messages.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_popup_menu.dart';
import '../widgets/reply_preview_bar.dart';
import '../widgets/pinned_message_banner.dart';
import '../widgets/delete_message_dialog.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  ReplyMessageModel? _activeReply;
  MessageModel? _pinnedMessage;

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
      replyTo: _activeReply?.originalMessage,
    );

    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
      _activeReply = null; // Clear reply after sending
    });

    // Simulate sending delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _sendImage(String imagePath) {
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '', // No text for image-only message
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
      imagePath: imagePath, // Add image path
      replyTo: _activeReply?.originalMessage,
    );

    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
      _activeReply = null; // Clear reply after sending
    });

    // Simulate sending delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    switch (action) {
      case MessageAction.reply:
        setState(() {
          _activeReply = ReplyMessageModel(
            originalMessage: message,
            username: message.isSent ? 'yourself' : widget.user.name,
            previewText: message.text.isNotEmpty ? message.text : 'Image',
          );
        });
        break;
      case MessageAction.forward:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forward feature coming soon!')),
        );
        break;
      case MessageAction.pin:
        setState(() {
          // Unpin existing message if any
          if (_pinnedMessage != null) {
            final pinnedIndex = _messages.indexWhere((msg) => msg.id == _pinnedMessage!.id);
            if (pinnedIndex != -1) {
              _messages[pinnedIndex] = _messages[pinnedIndex].copyWith(isPinned: false);
            }
          }
          
          // Pin new message
          final messageIndex = _messages.indexWhere((msg) => msg.id == message.id);
          if (messageIndex != -1) {
            _messages[messageIndex] = _messages[messageIndex].copyWith(isPinned: true);
            _pinnedMessage = _messages[messageIndex];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.name} pinned a message')),
        );
        break;
      case MessageAction.report:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report feature coming soon!')),
        );
        break;
      case MessageAction.delete:
        DeleteMessageDialog(
          onDeleteSelected: (option) {
            _handleDeleteMessage(option, message);
          },
        ).show(context);
        break;
    }
  }

  void _handleDeleteMessage(DeleteOption option, MessageModel message) {
    switch (option) {
      case DeleteOption.fromMe:
        setState(() {
          _messages.removeWhere((msg) => msg.id == message.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted from your chat')),
        );
        break;
      case DeleteOption.fromEveryone:
        setState(() {
          _messages.removeWhere((msg) => msg.id == message.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted for everyone')),
        );
        break;
    }
  }

  void _clearReply() {
    setState(() {
      _activeReply = null;
    });
  }

  List<MessageModel> _getSortedMessages() {
    // Sort messages: pinned messages first, then by timestamp
    final sorted = List<MessageModel>.from(_messages);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.timestamp.compareTo(b.timestamp);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedMessages = _getSortedMessages();
    
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
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final message = sortedMessages[index];
                  
                  // Show pinned message banner for pinned messages
                  if (message.isPinned) {
                    return Column(
                      children: [
                        PinnedMessageBanner(
                          pinnedMessage: message,
                          username: widget.user.name,
                        ),
                        ChatBubble(
                          message: message,
                          onActionSelected: (action) => _handleMessageAction(action, message),
                        ),
                      ],
                    );
                  }
                  
                  return ChatBubble(
                    message: message,
                    onActionSelected: (action) => _handleMessageAction(action, message),
                  );
                },
              ),
            ),

            /// Reply Preview Bar (if active)
            if (_activeReply != null)
              ReplyPreviewBar(
                replyMessage: _activeReply!,
                onClose: _clearReply,
              ),

            /// Chat Input Field
            ChatInputField(
              onSendMessage: _sendMessage,
              onSendImage: _sendImage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
