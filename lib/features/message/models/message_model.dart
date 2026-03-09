class MessageModel {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSent;
  final String senderId;

  const MessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSent,
    required this.senderId,
  });
}

class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  const ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}
