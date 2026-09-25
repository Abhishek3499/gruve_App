import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/message/data/datasource/message_service.dart';
import 'package:gruve_app/features/message/domain/entities/message_media_model.dart';
import 'package:gruve_app/features/message/domain/entities/message_model.dart';

enum UploadStatus { uploading, sending, done, failed }

class PendingUpload {
  final String localId;
  final String conversationId;
  final String filePath;
  final String mediaKind;
  final String? caption;
  final String? replyToMessageId;
  UploadStatus status;
  double progress; // 0.0 – 1.0

  PendingUpload({
    required this.localId,
    required this.conversationId,
    required this.filePath,
    required this.mediaKind,
    this.caption,
    this.replyToMessageId,
    this.status = UploadStatus.uploading,
    this.progress = 0.0,
  });
}

/// Singleton service that keeps media uploads alive even after the chat screen
/// is popped. Notifies listeners so any active ChatScreen can react.
class MediaUploadService extends ChangeNotifier {
  static final MediaUploadService _instance = MediaUploadService._internal();
  factory MediaUploadService() => _instance;
  MediaUploadService._internal();

  final _messageService = MessageService();
  final Map<String, PendingUpload> _uploads = {};

  List<PendingUpload> get uploads => _uploads.values.toList();

  /// Returns active uploads for a specific conversation.
  List<PendingUpload> uploadsFor(String conversationId) => _uploads.values
      .where((u) => u.conversationId == conversationId)
      .toList();

  bool hasActiveUploads(String conversationId) =>
      _uploads.values.any(
        (u) =>
            u.conversationId == conversationId &&
            (u.status == UploadStatus.uploading ||
                u.status == UploadStatus.sending),
      );

  /// Starts a background upload+send. Returns the [localId] immediately.
  Future<void> enqueue({
    required String localId,
    required String conversationId,
    required String filePath,
    required String mediaKind,
    String? caption,
    String? replyToMessageId,
    /// Called when the server confirms the message (success path).
    void Function(MessageModel message)? onSuccess,
    /// Called on failure so the caller can mark the bubble as failed.
    void Function(String localId)? onFailure,
  }) async {
    final upload = PendingUpload(
      localId: localId,
      conversationId: conversationId,
      filePath: filePath,
      mediaKind: mediaKind,
      caption: caption,
      replyToMessageId: replyToMessageId,
    );
    _uploads[localId] = upload;
    notifyListeners();

    try {
      // Step 1 — upload the file
      final media = await _messageService.uploadMessageMedia(
        conversationId: conversationId,
        filePath: filePath,
      );

      upload.status = UploadStatus.sending;
      upload.progress = 0.8;
      notifyListeners();

      // Step 2 — send the message
      final currentUserId = await TokenStorage.getCurrentUserId();
      final sent = await _messageService.sendMessage(
        conversationId: conversationId,
        content: caption?.isNotEmpty == true ? caption : null,
        replyToMessageId: replyToMessageId,
        media: media.toApiPayload(),
        currentUserId: currentUserId,
      );

      upload.status = UploadStatus.done;
      upload.progress = 1.0;
      notifyListeners();

      if (sent != null) onSuccess?.call(sent);

      AppLogger.d('[MediaUploadService] Upload done: $localId');
    } catch (e) {
      upload.status = UploadStatus.failed;
      notifyListeners();
      onFailure?.call(localId);
      AppLogger.d('[MediaUploadService] Upload failed: $localId — $e');
    } finally {
      // Keep failed uploads briefly so the UI can show the error state,
      // then remove them after 10 s.
      Future.delayed(const Duration(seconds: 10), () {
        _uploads.remove(localId);
        notifyListeners();
      });
    }
  }
}
