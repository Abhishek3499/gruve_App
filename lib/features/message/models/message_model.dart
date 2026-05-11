import 'package:flutter/foundation.dart';

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

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? receiverUserId,
  }) {
    final senderId = _stringValue(
      json['sender_id'] ??
          json['senderId'] ??
          json['sender']?['id'] ??
          json['user']?['id'],
    );

    final isSent = currentUserId != null && currentUserId.isNotEmpty
        ? senderId == currentUserId
        : receiverUserId != null && receiverUserId.isNotEmpty
            ? senderId != receiverUserId
            : json['is_sent'] == true || json['isSent'] == true;

    return MessageModel(
      id: _stringValue(json['id'] ?? json['_id']),
      text: _stringValue(json['content'] ?? json['text'] ?? json['message']),
      timestamp: _parseDateTime(
        json['created_at'] ?? json['createdAt'] ?? json['timestamp'],
      ),
      isSent: isSent,
      senderId: senderId,
      imagePath: _nullableString(
        json['image'] ?? json['image_url'] ?? json['media_url'] ?? json['file'],
      ),
      isRead: json['is_read'] == true || json['isRead'] == true,
    );
  }

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasReply => replyTo != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': text,
      'created_at': timestamp.toIso8601String(),
      'sender_id': senderId,
      'is_read': isRead,
      if (imagePath != null) 'image': imagePath,
    };
  }

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

  static String _stringValue(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    final parsed = value?.toString();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (error) {
        debugPrint('[MessageModel] Failed to parse timestamp "$value": $error');
      }
    }
    return DateTime.now();
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
