import 'package:gruve_app/features/message/domain/entities/message_model.dart';

/// Quoted message preview from `reply_to` in API / WebSocket payloads.
class MessageReplyPreview {
  final String messageId;
  final String senderId;
  final String senderName;
  final String contentPreview;
  final String messageKind;
  final String? mediaUrl;

  const MessageReplyPreview({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.contentPreview,
    this.messageKind = 'text',
    this.mediaUrl,
  });

  factory MessageReplyPreview.fromJson(Map<String, dynamic> json) {
    return MessageReplyPreview(
      messageId: json['message_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      contentPreview:
          json['content_preview']?.toString() ?? json['text']?.toString() ?? '',
      messageKind: json['message_kind']?.toString() ?? 'text',
      mediaUrl: json['media_url']?.toString(),
    );
  }

  factory MessageReplyPreview.fromMessage(MessageModel message, {String? senderName}) {
    return MessageReplyPreview(
      messageId: message.id,
      senderId: message.senderId,
      senderName: senderName ?? message.senderName ?? 'User',
      contentPreview: message.text.isNotEmpty
          ? message.text
          : (message.isVideo
              ? 'Video'
              : message.isAudio
                  ? 'Voice message'
                  : message.hasMedia
                      ? 'Photo'
                      : ''),
      messageKind: message.isVideo
          ? 'video'
          : (message.isAudio
              ? 'audio'
              : message.hasMedia
                  ? 'image'
                  : 'text'),
      mediaUrl: message.hasMedia && !message.isLocalMedia ? message.imagePath : null,
    );
  }

  String get displayText {
    if (contentPreview.trim().isNotEmpty) return contentPreview.trim();
    switch (messageKind.toLowerCase()) {
      case 'video':
        return 'Video';
      case 'image':
        return 'Photo';
      case 'audio':
        return 'Voice message';
      default:
        return '';
    }
  }
}
