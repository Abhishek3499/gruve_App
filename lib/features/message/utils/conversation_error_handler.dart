import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Centralized error handling for conversation operations
/// 
/// Provides consistent error handling and user feedback across the app
class ConversationErrorHandler {
  
  /// Handle conversation creation errors
  /// 
  /// [error] - The error that occurred
  /// [context] - BuildContext for showing user feedback (optional)
  /// [source] - Source where error occurred (for logging)
  /// 
  /// Returns user-friendly error message
  static String handleConversationError({
    required Object error,
    BuildContext? context,
    String? source,
  }) {
    final sourceInfo = source != null ? '[$source] ' : '';
    AppLogger.d('💥 [ConversationErrorHandler]${sourceInfo}Handling error: $error');
    
    String userMessage = 'Failed to open chat';
    
    if (error is ArgumentError) {
      userMessage = 'Invalid user information';
      AppLogger.d('🚫 [ConversationErrorHandler]${sourceInfo}ArgumentError: ${error.message}');
    } else if (error.toString().contains('Connection timeout')) {
      userMessage = 'Connection timeout. Please check your internet connection.';
      AppLogger.d('⏰ [ConversationErrorHandler]${sourceInfo}Connection timeout');
    } else if (error.toString().contains('No internet connection')) {
      userMessage = 'No internet connection. Please check your network.';
      AppLogger.d('📶 [ConversationErrorHandler]${sourceInfo}No internet');
    } else if (error.toString().contains('API Error')) {
      // Extract API error details
      final errorStr = error.toString();
      if (errorStr.contains('404')) {
        userMessage = 'User not found';
      } else if (errorStr.contains('401') || errorStr.contains('403')) {
        userMessage = 'Authentication error. Please login again.';
      } else if (errorStr.contains('429')) {
        userMessage = 'Too many requests. Please try again later.';
      } else if (errorStr.contains('500')) {
        userMessage = 'Server error. Please try again later.';
      } else {
        userMessage = 'Server error occurred. Please try again.';
      }
      AppLogger.d('🚫 [ConversationErrorHandler]${sourceInfo}API Error: $errorStr');
    } else if (error.toString().contains('Context is not mounted')) {
      userMessage = 'App state changed. Please try again.';
      AppLogger.d('⚠️ [ConversationErrorHandler]${sourceInfo}Context not mounted');
    } else if (error.toString().contains('already in progress')) {
      userMessage = 'Request already in progress. Please wait.';
      AppLogger.d('⏳ [ConversationErrorHandler]${sourceInfo}Duplicate request');
    } else {
      userMessage = 'Unexpected error occurred. Please try again.';
      AppLogger.d('❓ [ConversationErrorHandler]${sourceInfo}Unknown error: $error');
    }
    
    // Show user feedback if context is available
    if (context != null && context.mounted) {
      _showUserFeedback(context, userMessage);
    }
    
    return userMessage;
  }
  
  /// Show user feedback for errors
  /// 
  /// [context] - BuildContext for showing snackbar
  /// [message] - User-friendly error message
  static void _showUserFeedback(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      AppLogger.d('💥 [ConversationErrorHandler] Failed to show snackbar: $e');
    }
  }
  
  /// Show success feedback
  /// 
  /// [context] - BuildContext for showing snackbar
  /// [message] - Success message
  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    if (!context.mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      AppLogger.d('💥 [ConversationErrorHandler] Failed to show success snackbar: $e');
    }
  }
  
  /// Log conversation operation for debugging
  /// 
  /// [operation] - Operation being performed
  /// [receiverId] - Target user ID
  /// [receiverName] - Target user name
  /// [source] - Source of operation
  static void logOperation({
    required String operation,
    required String receiverId,
    required String receiverName,
    String? source,
  }) {
    final sourceInfo = source != null ? '[$source] ' : '';
    AppLogger.d('🔄 [ConversationErrorHandler]$sourceInfo$operation: $receiverName ($receiverId)');
  }
  
  /// Log conversation operation result
  /// 
  /// [operation] - Operation that was performed
  /// [success] - Whether operation was successful
  /// [conversationId] - Conversation ID (if available)
  /// [source] - Source of operation
  static void logResult({
    required String operation,
    required bool success,
    String? conversationId,
    String? source,
  }) {
    final sourceInfo = source != null ? '[$source] ' : '';
    final status = success ? '✅ SUCCESS' : '❌ FAILED';
    final convInfo = conversationId != null ? ' (conv: $conversationId)' : '';
    
    AppLogger.d('📊 [ConversationErrorHandler]$sourceInfo$operation: $status$convInfo');
  }
}
