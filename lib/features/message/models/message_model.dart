import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import '../../../core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import '../utils/shared_post_message_parser.dart';
import 'message_reply_preview.dart';

enum MessageStatus {
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}

class MessageModel {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSent;
  final String senderId;
  final String? imagePath;
  final String? mediaKind;
  final MessageModel? replyTo;
  final MessageReplyPreview? replyPreview;
  final bool isPinned;
  final bool isRead;
  final String? senderAvatar;
  final String? senderName;
  final MessageStatus status;
  final String? sharedPostId;
  final String? sharedPostPreviewUrl;
  final Post? sharedPost;
  final bool isEdited;

  const MessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSent,
    required this.senderId,
    this.imagePath,
    this.mediaKind,
    this.replyTo,
    this.replyPreview,
    this.isPinned = false,
    this.isRead = false,
    this.senderAvatar,
    this.senderName,
    this.status = MessageStatus.sent,
    this.sharedPostId,
    this.sharedPostPreviewUrl,
    this.sharedPost,
    this.isEdited = false,
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

    final explicitIsRead = _resolveIsRead(safeJson);
    final status = _resolveStatus(safeJson, explicitIsRead);
    final messageText = _resolveMessageText(safeJson);
    final sharedPostId = SharedPostMessageParser.extractPostId(
      safeJson,
      messageText,
    );
    final sharedPostPreviewUrl = sharedPostId != null
        ? SharedPostMessageParser.extractPreviewUrl(
            safeJson,
            postId: sharedPostId,
          )
        : null;

    final sharedPostMap = safeJson['shared_post'] ??
        safeJson['tagged_post'] ??
        safeJson['post'] ??
        safeJson['attachment'];
    Post? sharedPost;
    if (sharedPostMap is Map && sharedPostId != null) {
      final postMap = Map<String, dynamic>.from(sharedPostMap);
      if (postMap['id'] == null) {
        postMap['id'] = sharedPostId;
      }
      try {
        final parsed = Post.fromJson(postMap);
        if (parsed.username != 'unknown') {
          sharedPost = parsed;
        }
      } catch (e) {
        AppLogger.d('⚠️ Error parsing sharedPost in MessageModel.fromJson: $e');
      }
    }

    final mediaUrl = _resolveMediaUrl(safeJson);
    final resolvedMediaKind = _resolveMediaKind(safeJson);
    final replyPreview = _parseReplyPreview(safeJson);

    return MessageModel(
      id: _resolveMessageId(safeJson),
      text: messageText,
      timestamp: _parseDateTime(
        safeJson['created_at'] ?? safeJson['createdAt'] ?? safeJson['timestamp'],
      ),
      isSent: isSent,
      senderId: senderId,
      imagePath: mediaUrl,
      mediaKind: resolvedMediaKind,
      replyPreview: replyPreview,
      isPinned: SafeParsingHelpers.safeBool(
        safeJson,
        const ['is_pinned', 'isPinned'],
        fallback: false,
      ),
      isRead: status == MessageStatus.read,
      senderAvatar: senderAvatar,
      senderName: senderName,
      status: status,
      sharedPostId: sharedPostId,
      sharedPostPreviewUrl: sharedPostPreviewUrl,
      sharedPost: sharedPost,
      isEdited: SafeParsingHelpers.safeBool(
        safeJson,
        const ['is_edited', 'isEdited'],
        fallback: false,
      ),
    );
  }

  bool get hasImage => hasMedia;
  bool get hasMedia => imagePath != null && imagePath!.isNotEmpty;
  bool get isLocalMedia {
    final path = imagePath?.trim() ?? '';
    if (path.isEmpty) return false;
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  bool get isVideo =>
      mediaKind?.toLowerCase() == 'video' ||
      (hasMedia && !isLocalMedia && _urlLooksLikeVideo(imagePath!));

  static bool _urlLooksLikeVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    const hints = ['.mp4', '.mov', '.m4v', '.webm', '.mkv', '.3gp'];
    for (final h in hints) {
      if (lower.contains(h)) return true;
    }
    return false;
  }

  bool get hasReply => replyPreview != null || replyTo != null;

  MessageReplyPreview? get effectiveReplyPreview {
    if (replyPreview != null) return replyPreview;
    if (replyTo == null) return null;
    return MessageReplyPreview.fromMessage(replyTo!);
  }

  bool get isSharedPost => sharedPostId != null && sharedPostId!.isNotEmpty;
  bool get isEditable =>
      isSent &&
      !hasMedia &&
      !isSharedPost &&
      !id.startsWith('local-');

  String? get sharedPostCompanionText {
    if (!isSharedPost) return null;
    return SharedPostMessageParser.companionText(text, sharedPostId!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': text,
      'created_at': timestamp.toIso8601String(),
      'sender_id': senderId,
      'is_read': isRead,
      'status': status.name,
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
    String? mediaKind,
    MessageModel? replyTo,
    MessageReplyPreview? replyPreview,
    bool? isPinned,
    bool? isRead,
    String? senderAvatar,
    String? senderName,
    MessageStatus? status,
    String? sharedPostId,
    String? sharedPostPreviewUrl,
    Post? sharedPost,
    bool? isEdited,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSent: isSent ?? this.isSent,
      senderId: senderId ?? this.senderId,
      imagePath: imagePath ?? this.imagePath,
      mediaKind: mediaKind ?? this.mediaKind,
      replyTo: replyTo ?? this.replyTo,
      replyPreview: replyPreview ?? this.replyPreview,
      isPinned: isPinned ?? this.isPinned,
      isRead: isRead ?? (status != null ? status == MessageStatus.read : this.isRead),
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderName: senderName ?? this.senderName,
      status: status ?? this.status,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      sharedPostPreviewUrl:
          sharedPostPreviewUrl ?? this.sharedPostPreviewUrl,
      sharedPost: sharedPost ?? this.sharedPost,
      isEdited: isEdited ?? this.isEdited,
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

  static String? _resolveMediaUrl(Map<String, dynamic> json) {
    final media = json['media'];
    if (media is Map) {
      final mediaMap = Map<String, dynamic>.from(media);
      final url = mediaMap['media_url']?.toString().trim();
      if (url != null && url.isNotEmpty) return url;
    }

    final attachments = json['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        final url = map['media_url']?.toString().trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }

    final content = json['content'];
    if (content is Map) {
      final contentMap = Map<String, dynamic>.from(content);
      final type = contentMap['type']?.toString().toLowerCase();
      if (type == 'image' || type == 'video') {
        final directUrl = contentMap['url'] ??
            contentMap['media_url'] ??
            contentMap['image_url'];
        final url = directUrl?.toString().trim();
        if (url != null && url.isNotEmpty) return url;
      }
      final metadata = contentMap['metadata'];
      if (metadata is Map) {
        final metaMap = Map<String, dynamic>.from(metadata);
        final url = metaMap['media_url']?.toString().trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }

    return SafeParsingHelpers.safeNullableString(
      json,
      const ['image', 'image_url', 'media_url', 'file'],
    );
  }

  static String? _resolveMediaKind(Map<String, dynamic> json) {
    final media = json['media'];
    if (media is Map) {
      final kind = Map<String, dynamic>.from(media)['media_kind']?.toString();
      if (kind != null && kind.isNotEmpty) return kind;
    }

    final attachments = json['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final kind = Map<String, dynamic>.from(first)['media_kind']?.toString();
        if (kind != null && kind.isNotEmpty) return kind;
      }
    }

    final content = json['content'];
    if (content is Map) {
      final contentMap = Map<String, dynamic>.from(content);
      final type = contentMap['type']?.toString();
      if (type != null && type.isNotEmpty && type != 'text') return type;
      final metadata = contentMap['metadata'];
      if (metadata is Map) {
        final kind =
            Map<String, dynamic>.from(metadata)['media_kind']?.toString();
        if (kind != null && kind.isNotEmpty) return kind;
      }
    }

    return null;
  }

  static MessageReplyPreview? _parseReplyPreview(Map<String, dynamic> json) {
    final raw = json['reply_to'];
    if (raw is! Map) return null;
    return MessageReplyPreview.fromJson(Map<String, dynamic>.from(raw));
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

  static MessageStatus _resolveStatus(Map<String, dynamic> json, bool fallbackIsRead) {
    final statusStr = json['status']?.toString();
    if (statusStr != null && statusStr.isNotEmpty) {
      return MessageStatus.fromString(statusStr);
    }

    final deliveryStatus = json['delivery_status'];
    if (deliveryStatus is Map) {
      final deliveryMap = Map<String, dynamic>.from(deliveryStatus);
      final readAt = deliveryMap['read_at'] ?? deliveryMap['readAt'];
      if (readAt != null && readAt.toString().trim().isNotEmpty) {
        return MessageStatus.read;
      }
      final deliveredAt = deliveryMap['delivered_at'] ?? deliveryMap['deliveredAt'];
      if (deliveredAt != null && deliveredAt.toString().trim().isNotEmpty) {
        return MessageStatus.delivered;
      }
    }

    if (fallbackIsRead) {
      return MessageStatus.read;
    }

    return MessageStatus.sent;
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
