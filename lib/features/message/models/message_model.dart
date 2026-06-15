import '../../../core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d('[MessageModel] Starting message parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(
      json,
      context: 'MessageModel.fromJson',
    );
    AppLogger.d('[MessageModel] Message keys: ${safeJson.keys.toList()}');

    final senderObj = safeJson['sender'] is Map
        ? Map<String, dynamic>.from(safeJson['sender'] as Map)
        : <String, dynamic>{};
    final senderId = _resolveSenderId(safeJson, senderObj);
    final senderAvatar = SafeParsingHelpers.safeNullableString(
      senderObj,
      const [
        'avatar',
        'profile_picture',
        'profilePicture',
        'profile_image',
        'profileImage',
      ],
    );
    final senderName = SafeParsingHelpers.safeNullableString(
      senderObj,
      const ['name', 'username', 'full_name', 'fullName'],
    );

    final isSent = currentUserId != null && currentUserId.isNotEmpty
        ? senderId == currentUserId
        : receiverUserId != null && receiverUserId.isNotEmpty
        ? senderId != receiverUserId
        : SafeParsingHelpers.safeBool(
            safeJson,
            const ['is_sent', 'isSent'],
            fallback: false,
          );

    return MessageModel(
      id: _resolveMessageId(safeJson),
      text: _resolveMessageText(safeJson),
      timestamp: _parseDateTime(
        safeJson['created_at'] ?? safeJson['createdAt'] ?? safeJson['timestamp'],
      ),
      isSent: isSent,
      senderId: senderId,
      imagePath: SafeParsingHelpers.safeNullableString(
        safeJson,
        const ['image', 'image_url', 'media_url', 'file'],
      ),
      isPinned: SafeParsingHelpers.safeBool(
        safeJson,
        const ['is_pinned', 'isPinned'],
        fallback: false,
      ),
      isRead: _resolveIsRead(safeJson),
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

  static String _resolveSenderId(
    Map<String, dynamic> json,
    Map<String, dynamic> senderObj,
  ) {
    final nestedSenderId = SafeParsingHelpers.safeString(
      senderObj,
      const ['id', 'user_id', 'userId'],
      fallback: '',
    );
    if (nestedSenderId.isNotEmpty) return nestedSenderId;

    return SafeParsingHelpers.safeString(
      json,
      const ['sender_id', 'senderId', 'user_id', 'userId'],
      fallback: '',
    );
  }

  static String _resolveMessageId(Map<String, dynamic> json) {
    final explicitId = SafeParsingHelpers.safeString(
      json,
      const [
        'id',
        '_id',
        'message_id',
        'messageId',
        'client_message_id',
        'clientMessageId',
      ],
      fallback: '',
    );
    if (explicitId.isNotEmpty) return explicitId;

    final timestamp = json['created_at'] ?? json['createdAt'] ?? json['timestamp'];
    final sender = json['sender_id'] ?? json['senderId'] ?? json['sender'] ?? '';
    final content = _resolveMessageText(json);
    final seed = '$timestamp|$sender|$content';
    return 'realtime_${seed.hashCode.abs()}';
  }

  static String _resolveMessageText(Map<String, dynamic> json) {
    final content = json['content'];
    if (content is Map) {
      final contentMap = Map<String, dynamic>.from(content);
      final text = SafeParsingHelpers.safeString(
        contentMap,
        const ['text', 'message', 'value'],
        fallback: '',
      );
      if (text.isNotEmpty) return text;
    }

    return SafeParsingHelpers.safeString(
      json,
      const ['content', 'text', 'message'],
      fallback: '',
    );
  }

  static bool _resolveIsRead(Map<String, dynamic> json) {
    final explicit = SafeParsingHelpers.safeBool(
      json,
      const ['is_read', 'isRead'],
      fallback: false,
    );
    if (explicit) return true;

    final deliveryStatus = json['delivery_status'];
    if (deliveryStatus is Map) {
      final deliveryMap = Map<String, dynamic>.from(deliveryStatus);
      final readAt = deliveryMap['read_at'] ?? deliveryMap['readAt'];
      return readAt != null && readAt.toString().trim().isNotEmpty;
    }

    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (error) {
        AppLogger.d('[MessageModel] Failed to parse timestamp "$value": $error');
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
