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
    return originalMessage.text.isNotEmpty 
        ? originalMessage.text 
        : 'Image';
  }
}
