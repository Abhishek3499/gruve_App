import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';
import '../screen/chat_screen.dart';
import '../utils/conversation_error_handler.dart';

/// Controller for handling conversation creation and navigation
/// 
/// This controller manages:
/// - Creating or retrieving conversations with users
/// - Loading states and error handling
/// - Duplicate request prevention
/// - Production-level logging
class ConversationController extends ChangeNotifier {
  final MessageService _messageService;
  
  ConversationController(this._messageService) {
    debugPrint('🏗️ [ConversationController] Controller initialized');
  }

  // State variables
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;
  final Set<String> _activeRequests = {};
  
  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;
  bool get disposed => _disposed;

  /// Clear any existing error
  void clearError() {
    if (_error != null) {
      _error = null;
      _notify();
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('⏳ [ConversationController] Loading state changed: $loading');
      _notify();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      debugPrint('❌ [ConversationController] Error state changed: $error');
      _notify();
    }
  }

  /// Create or get a conversation with a user
  /// 
  /// [receiverId] - The ID of the user to create/retrieve conversation with
  /// Returns [ConversationModel] on success
  /// Throws [Exception] on errors
  Future<ConversationModel> createOrGetConversation(String receiverId) async {
    if (receiverId.isEmpty) {
      throw ArgumentError('Receiver ID cannot be empty');
    }

    // Prevent duplicate requests for the same receiver
    if (_activeRequests.contains(receiverId)) {
      debugPrint('🔒 [ConversationController] Request already active for receiver: $receiverId');
      throw Exception('Conversation request already in progress');
    }

    if (_isLoading) {
      debugPrint('⏳ [ConversationController] Already creating conversation, waiting...');
      throw Exception('Conversation creation already in progress');
    }

    _activeRequests.add(receiverId);
    _setLoading(true);
    clearError();

    try {
      debugPrint('🚀 [ConversationController] Starting conversation creation for receiver: $receiverId');
      
      final conversation = await _messageService.createOrGetConversation(receiverId);
      
      if (_disposed) return conversation;
      
      debugPrint('✅ [ConversationController] 🎉 Successfully created/retrieved conversation: ${conversation.id}');
      debugPrint('💬 [ConversationController] 👤 Participants: ${conversation.participant_1_id} & ${conversation.participant_2_id}');
      
      return conversation;
    } catch (e) {
      if (_disposed) rethrow;
      
      // Use centralized error handling
      final userMessage = ConversationErrorHandler.handleConversationError(
        error: e,
        source: 'ConversationController',
      );
      _setError(userMessage);
      rethrow;
    } finally {
      _activeRequests.remove(receiverId);
      _setLoading(false);
    }
  }

  /// Navigate to chat screen with a user
  /// 
  /// [receiverId] - The ID of the user to chat with
  /// [receiverName] - The name of the user (for logging and display)
  /// [receiverProfileImage] - The profile image URL of the user (for display)
  /// [context] - BuildContext for navigation
  /// Returns [ConversationModel] after successful navigation
  Future<ConversationModel> navigateToChat({
    required String receiverId,
    required String receiverName,
    String? receiverProfileImage,
    required BuildContext context,
  }) async {
    if (!context.mounted) {
      throw Exception('Context is not mounted');
    }

    try {
      debugPrint('🧭 [ConversationController] Starting navigation flow to chat with: $receiverName ($receiverId)');
      if (receiverProfileImage != null) {
        debugPrint('🖼️ [ConversationController] Profile image provided: $receiverProfileImage');
      }
      
      // Create or get conversation
      final conversation = await createOrGetConversation(receiverId);
      
      if (!context.mounted) {
        debugPrint('⚠️ [ConversationController] Context unmounted after API call');
        throw Exception('Context is no longer mounted');
      }
      
      debugPrint('📱 [ConversationController] Navigating to ChatScreen with conversation: ${conversation.id}');
      debugPrint('👤 [ConversationController] Passing user data: name=$receiverName, image=${receiverProfileImage ?? "none"}');
      
      // Navigate to ChatScreen with explicit user data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversation.id,
            receiverId: receiverId,
            userName: receiverName,
            profileImage: receiverProfileImage,
            userOrConversation: conversation, // Keep for backward compatibility
          ),
        ),
      );
      
      return conversation;
    } catch (e) {
      // Use centralized error handling
      ConversationErrorHandler.handleConversationError(
        error: e,
        context: context,
        source: 'ConversationController.navigateToChat',
      );
      
      rethrow;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    _activeRequests.clear();
    debugPrint('🗑️ [ConversationController] Controller disposed (cleared ${_activeRequests.length} active requests)');
    super.dispose();
  }
}
