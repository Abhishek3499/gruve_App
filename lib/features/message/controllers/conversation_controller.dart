import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';
import '../screen/chat_screen.dart';
import '../utils/conversation_error_handler.dart';
import '../providers/message_provider.dart';

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
      debugPrint('🔒 [ConversationController] ⚠️ Request already active for receiver: $receiverId');
      debugPrint('⏸️ [ConversationController] 🚫 Preventing duplicate API call');
      throw Exception('Conversation request already in progress');
    }

    if (_isLoading) {
      debugPrint('⏳ [ConversationController] ⚠️ Already creating conversation, waiting...');
      throw Exception('Conversation creation already in progress');
    }

    _activeRequests.add(receiverId);
    debugPrint('📦 [ConversationController] 📝 Added receiver to active requests: $receiverId');
    debugPrint('📊 [ConversationController] 📈 Active requests count: ${_activeRequests.length}');
    
    _setLoading(true);
    clearError();

    try {
      debugPrint('🚀 [ConversationController] 🌐 Starting conversation creation for receiver: $receiverId');
      debugPrint('📡 [ConversationController] 📶 Calling API: POST /conversations/');
      
      final conversation = await _messageService.createOrGetConversation(receiverId);
      
      if (_disposed) {
        debugPrint('⚠️ [ConversationController] 🗑️ Controller disposed, returning conversation without update');
        return conversation;
      }
      
      debugPrint('✅ [ConversationController] 🎉 Successfully created/retrieved conversation!');
      debugPrint('💬 [ConversationController] 🆔 Conversation ID: ${conversation.id}');
      debugPrint('👤 [ConversationController] 👥 Participant 1: ${conversation.participant1Id}');
      debugPrint('👤 [ConversationController] 👥 Participant 2: ${conversation.participant2Id}');
      debugPrint('👤 [ConversationController] 👨 Other user: ${conversation.otherUser.name}');
      
      return conversation;
    } catch (e) {
      if (_disposed) rethrow;
      
      debugPrint('❌ [ConversationController] 💥 Error creating/getting conversation');
      debugPrint('🔥 [ConversationController] 📋 Error details: $e');
      
      // Use centralized error handling
      final userMessage = ConversationErrorHandler.handleConversationError(
        error: e,
        source: 'ConversationController',
      );
      _setError(userMessage);
      rethrow;
    } finally {
      _activeRequests.remove(receiverId);
      debugPrint('🧹 [ConversationController] 🗑️ Removed receiver from active requests: $receiverId');
      debugPrint('📊 [ConversationController] 📉 Active requests count: ${_activeRequests.length}');
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
      debugPrint('❌ [ConversationController] ⚠️ Context is not mounted');
      throw Exception('Context is not mounted');
    }

    try {
      debugPrint('🧭 [ConversationController] 🚀 Starting navigation flow');
      debugPrint('👤 [ConversationController] 🎯 Target user: $receiverName ($receiverId)');
      if (receiverProfileImage != null) {
        debugPrint('🖼️ [ConversationController] 📸 Profile image: $receiverProfileImage');
      } else {
        debugPrint('🖼️ [ConversationController] ❌ No profile image provided');
      }
      
      debugPrint('📡 [ConversationController] 🌐 Creating/getting conversation...');
      // Create or get conversation
      final conversation = await createOrGetConversation(receiverId);
      
      if (!context.mounted) {
        debugPrint('⚠️ [ConversationController] ❌ Context unmounted after API call');
        throw Exception('Context is no longer mounted');
      }
      
      debugPrint('📊 [ConversationController] 📝 Checking MessageProvider for existing conversation');
      // Add conversation to MessageProvider if not already present
      final messageProvider = context.read<MessageProvider>();
      final existingConversation = messageProvider.getConversationById(conversation.id);
      
      if (existingConversation == null) {
        debugPrint('➕ [ConversationController] 🆕 Adding new conversation to MessageProvider');
        debugPrint('💬 [ConversationController] 🆔 Conversation ID: ${conversation.id}');
        messageProvider.addConversation(conversation);
        debugPrint('✅ [ConversationController] ✔️ Conversation added to provider');
      } else {
        debugPrint('✅ [ConversationController] 💬 Conversation already exists in provider');
        debugPrint('🔄 [ConversationController] ⏭️ Skipping duplicate addition');
      }
      
      debugPrint('📱 [ConversationController] 🚀 Navigating to ChatScreen');
      debugPrint('🆔 [ConversationController] 💬 Conversation ID: ${conversation.id}');
      debugPrint('👤 [ConversationController] 👨 User name: $receiverName');
      debugPrint('🖼️ [ConversationController] 📸 Profile image: ${receiverProfileImage ?? "none"}');
      
      // Navigate to ChatScreen with explicit user data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversation.id,
            receiverId: receiverId,
            userName: receiverName,
            profileImage: receiverProfileImage,
            userOrConversation: conversation,
          ),
        ),
      );
      
      debugPrint('✅ [ConversationController] 🎉 Navigation completed successfully');
      return conversation;
    } catch (e) {
      debugPrint('❌ [ConversationController] 💥 Navigation failed');
      debugPrint('🔥 [ConversationController] 📋 Error: $e');
      
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
