import '../models/message_model.dart';
class ReplyMessageModel {
  final MessageModel originalMessage;
  final String username;
  final String? previewText;

  const ReplyMessageModel({
    required this.originalMessage,
    required this.username,
    this.previewText,
  });

  String get displayText {
    if (previewText != null && previewText!.isNotEmpty) {
      return previewText!;
    }
    final quoted = originalMessage.effectiveReplyPreview;
    if (quoted != null && quoted.displayText.isNotEmpty) {
      return quoted.displayText;
    }
    if (originalMessage.text.isNotEmpty) return originalMessage.text;
    if (originalMessage.isVideo) return 'Video';
    if (originalMessage.hasMedia) return 'Photo';
    return 'Message';
  }
}
