class MessageModel {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSent;
  final String senderId;
  final String? imagePath;
  final MessageModel? replyTo;
  final bool isPinned;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSent,
    required this.senderId,
    this.imagePath,
    this.replyTo,
    this.isPinned = false,
    this.isRead = false,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasReply => replyTo != null;

  MessageModel copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isSent,
    String? senderId,
    String? imagePath,
    MessageModel? replyTo,
    bool? isPinned,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSent: isSent ?? this.isSent,
      senderId: senderId ?? this.senderId,
      imagePath: imagePath ?? this.imagePath,
      replyTo: replyTo ?? this.replyTo,
      isPinned: isPinned ?? this.isPinned,
      isRead: isRead ?? this.isRead,
    );
  }
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
