import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/message/presentation/notifiers/message_notifier.dart';
import 'package:gruve_app/features/message/presentation/screens/chat_screen.dart';
import 'package:gruve_app/features/message/utils/conversation_error_handler.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Utility class for handling conversation creation across the app
///
/// This provides a centralized way to create conversations from any user interaction point
/// including: message avatars, profile message buttons, follower/following users, etc.
class ConversationUtils {
  /// Navigate to chat with a user
  ///
  /// This is the main entry point for all conversation creation flows in the app.
  ///
  /// [context] - BuildContext for navigation
  /// [ref] - WidgetRef for reading the message conversation-list state
  /// [receiverId] - The ID of the user to chat with
  /// [receiverName] - The name of the user (for logging and error messages)
  /// [receiverProfileImage] - The profile image URL of the user (for chat header display)
  /// [source] - Optional source identifier for debugging (e.g., 'message_avatar', 'follow_tile')
  ///
  /// Usage examples:
  /// ```dart
  /// // From follow tile message button
  /// ConversationUtils.navigateToChat(
  ///   context: context,
  ///   ref: ref,
  ///   receiverId: follower.id,
  ///   receiverName: follower.username,
  ///   receiverProfileImage: follower.profileImage,
  ///   source: 'follow_tile',
  /// );
  /// ```
  static Future<void> navigateToChat({
    required BuildContext context,
    required WidgetRef ref,
    required String receiverId,
    required String receiverName,
    String? receiverProfileImage,
    String? source,
  }) async {
    if (!context.mounted) {
      AppLogger.d(
        '⚠️ [ConversationUtils] Context not mounted, cannot navigate',
      );
      return;
    }

    if (receiverId.isEmpty) {
      AppLogger.d(
        '⚠️ [ConversationUtils] Receiver ID is empty, cannot create conversation',
      );
      ConversationErrorHandler.handleConversationError(
        error: ArgumentError('Receiver ID cannot be empty'),
        context: context,
        source: source,
      );
      return;
    }

    ConversationErrorHandler.logOperation(
      operation: 'Starting conversation flow (immediate)',
      receiverId: receiverId,
      receiverName: receiverName,
      source: source,
    );

    try {
      final messageNotifier = ref.read(messageNotifierProvider.notifier);
      final existingConversation = messageNotifier.getConversationByUserId(
        receiverId,
      );

      if (!context.mounted) return;

      if (existingConversation != null) {
        AppLogger.d(
          '🧭 [ConversationUtils] Navigating to existing conversation: ${existingConversation.id}',
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: existingConversation.id,
              receiverId: receiverId,
              userName: receiverName,
              profileImage: receiverProfileImage,
              userOrConversation: existingConversation,
            ),
          ),
        );
      } else {
        AppLogger.d(
          '🧭 [ConversationUtils] Navigating to new chat screen immediately (async resolve)',
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverId: receiverId,
              userName: receiverName,
              profileImage: receiverProfileImage,
            ),
          ),
        );
      }

      if (context.mounted) {
        AppLogger.d(
          '🔄 [ConversationUtils] Returned from ChatScreen, refreshing list',
        );
        unawaited(messageNotifier.fetchConversations(refresh: true));
      }
    } catch (e) {
      ConversationErrorHandler.logResult(
        operation: 'Conversation navigation',
        success: false,
        source: source,
      );

      if (context.mounted) {
        ConversationErrorHandler.handleConversationError(
          error: e,
          context: context,
          source: source,
        );
      }
    }
  }

  /// Check if a conversation can be created with the given user
  ///
  /// [receiverId] - The ID of the user to check
  /// Returns true if conversation can be created, false otherwise
  static bool canCreateConversation(String receiverId) {
    return receiverId.isNotEmpty;
  }
}
