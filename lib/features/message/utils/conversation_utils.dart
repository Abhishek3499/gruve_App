import 'package:flutter/material.dart';
import '../controllers/conversation_controller.dart';
import '../services/message_service.dart';
import '../models/conversation_model.dart';
import 'conversation_error_handler.dart';
import 'user_display_helper.dart';

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
  /// [receiverId] - The ID of the user to chat with
  /// [receiverName] - The name of the user (for logging and error messages)
  /// [receiverProfileImage] - The profile image URL of the user (for chat header display)
  /// [source] - Optional source identifier for debugging (e.g., 'message_avatar', 'follow_tile')
  /// 
  /// Usage examples:
  /// ```dart
  /// // From message avatar tap
  /// ConversationUtils.navigateToChat(
  ///   context: context,
  ///   receiverId: user.id,
  ///   receiverName: user.name,
  ///   receiverProfileImage: user.profileImage,
  ///   source: 'message_avatar',
  /// );
  /// 
  /// // From follow tile message button
  /// ConversationUtils.navigateToChat(
  ///   context: context,
  ///   receiverId: follower.id,
  ///   receiverName: follower.username,
  ///   receiverProfileImage: follower.profileImage,
  ///   source: 'follow_tile',
  /// );
  /// ```
  static Future<void> navigateToChat({
    required BuildContext context,
    required String receiverId,
    required String receiverName,
    String? receiverProfileImage,
    String? source,
  }) async {
    if (!context.mounted) {
      debugPrint('⚠️ [ConversationUtils] Context not mounted, cannot navigate');
      return;
    }

    if (receiverId.isEmpty) {
      debugPrint('⚠️ [ConversationUtils] Receiver ID is empty, cannot create conversation');
      ConversationErrorHandler.handleConversationError(
        error: ArgumentError('Receiver ID cannot be empty'),
        context: context,
        source: source,
      );
      return;
    }

    ConversationErrorHandler.logOperation(
      operation: 'Starting conversation flow',
      receiverId: receiverId,
      receiverName: receiverName,
      source: source,
    );

    try {
      // Create conversation controller for this operation
      final conversationController = ConversationController(MessageService());
      
      final conversation = await conversationController.navigateToChat(
        receiverId: receiverId,
        receiverName: receiverName,
        receiverProfileImage: receiverProfileImage,
        context: context,
      );
      
      ConversationErrorHandler.logResult(
        operation: 'Conversation navigation',
        success: true,
        conversationId: conversation.id,
        source: source,
      );
      
      if (context.mounted) {
        ConversationErrorHandler.showSuccess(
          context: context,
          message: 'Chat opened successfully',
        );
      }
    } catch (e) {
      ConversationErrorHandler.logResult(
        operation: 'Conversation navigation',
        success: false,
        source: source,
      );
      
      ConversationErrorHandler.handleConversationError(
        error: e,
        context: context,
        source: source,
      );
    }
  }

  /// Create a conversation without navigation
  /// 
  /// Useful for pre-creating conversations or when you need the conversation object
  /// but don't want to navigate immediately.
  /// 
  /// [receiverId] - The ID of the user to create conversation with
  /// [receiverName] - The name of the user (for logging)
  /// [source] - Optional source identifier for debugging
  /// 
  /// Returns [ConversationModel] on success
  /// Throws [Exception] on errors
  static Future<ConversationModel> createConversation({
    required String receiverId,
    required String receiverName,
    String? source,
  }) async {
    if (receiverId.isEmpty) {
      throw ArgumentError('Receiver ID cannot be empty');
    }

    // Log operation start
    ConversationErrorHandler.logOperation(
      operation: 'Creating conversation',
      receiverId: receiverId,
      receiverName: receiverName,
      source: source,
    );

    final conversationController = ConversationController(MessageService());
    
    try {
      final conversation = await conversationController.createOrGetConversation(receiverId);
      
      // Log successful result
      ConversationErrorHandler.logResult(
        operation: 'Conversation creation',
        success: true,
        conversationId: conversation.id,
        source: source,
      );
      
      return conversation;
    } catch (e) {
      // Log failed result
      ConversationErrorHandler.logResult(
        operation: 'Conversation creation',
        success: false,
        source: source,
      );
      
      // Use centralized error handling (without context since this is utility method)
      ConversationErrorHandler.handleConversationError(
        error: e,
        source: source,
      );
      
      rethrow;
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
