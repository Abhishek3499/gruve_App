import 'package:flutter/foundation.dart';
import '../../../core/parsing/safe_parsing_helpers.dart';

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
  final String? senderAvatar;
  final String? senderName;

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
    this.senderAvatar,
    this.senderName,
  });

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? receiverUserId,
  }) {
    debugPrint('📨 [MessageModel] 🔍 Starting message parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(json, context: '📨 MessageModel.fromJson');
    debugPrint('📨 [MessageModel] 🗺️ Message keys: ${safeJson.keys.toList()}');
    
    // Parse nested sender object if present
    final senderObj = safeJson['sender'] is Map<String, dynamic>
        ? safeJson['sender'] as Map<String, dynamic>
        : null;

    final senderId = senderObj?['id']?.toString() ??
        SafeParsingHelpers.safeString(safeJson, const [
          'sender_id',
          'senderId',
          'sender.id',
          'user.id',
        ], fallback: '');

    final senderAvatar = senderObj?['avatar']?.toString();
    final senderName = senderObj?['name']?.toString() ?? senderObj?['username']?.toString();

    final isSent = currentUserId != null && currentUserId.isNotEmpty
        ? senderId == currentUserId
        : receiverUserId != null && receiverUserId.isNotEmpty
            ? senderId != receiverUserId
            : SafeParsingHelpers.safeBool(safeJson, const ['is_sent', 'isSent'], fallback: false);

    return MessageModel(
      id: SafeParsingHelpers.safeString(safeJson, const ['id', '_id'], fallback: ''),
      text: SafeParsingHelpers.safeString(safeJson, const ['content', 'text', 'message'], fallback: ''),
      timestamp: _parseDateTime(
        safeJson['created_at'] ?? safeJson['createdAt'] ?? safeJson['timestamp'],
      ),
      isSent: isSent,
      senderId: senderId,
      imagePath: SafeParsingHelpers.safeNullableString(
        safeJson,
        const ['image', 'image_url', 'media_url', 'file'],
      ),
      isRead: SafeParsingHelpers.safeBool(safeJson, const ['is_read', 'isRead'], fallback: false),
      senderAvatar: senderAvatar,
      senderName: senderName,
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
    String? senderAvatar,
    String? senderName,
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
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderName: senderName ?? this.senderName,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
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
