import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';
import '../screen/chat_screen.dart';
import '../utils/conversation_error_handler.dart';
import '../providers/message_provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d('🏗️ [ConversationController] Controller initialized');
  }

  // State variables
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;
  final Set<String> _activeRequests = {};
  final Map<String, Future<ConversationModel>> _inFlightRequests = {};
  
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
      AppLogger.d('⏳ [ConversationController] Loading state changed: $loading');
      _notify();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      AppLogger.d('❌ [ConversationController] Error state changed: $error');
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

    final inFlight = _inFlightRequests[receiverId];
    if (inFlight != null) {
      AppLogger.d('🔒 [ConversationController] Joining active request for receiver: $receiverId');
      return inFlight;
    }

    final future = _runCreateOrGetConversation(receiverId);
    _inFlightRequests[receiverId] = future;
    try {
      return await future;
    } finally {
      _inFlightRequests.remove(receiverId);
    }
  }

  Future<ConversationModel> _runCreateOrGetConversation(String receiverId) async {

    // Prevent duplicate requests for the same receiver
    if (_activeRequests.contains(receiverId)) {
      AppLogger.d('🔒 [ConversationController] ⚠️ Request already active for receiver: $receiverId');
      AppLogger.d('⏸️ [ConversationController] 🚫 Preventing duplicate API call');
      throw Exception('Conversation request already in progress');
    }

    if (_isLoading) {
      AppLogger.d('⏳ [ConversationController] ⚠️ Already creating conversation, waiting...');
      throw Exception('Conversation creation already in progress');
    }

    _activeRequests.add(receiverId);
    AppLogger.d('📦 [ConversationController] 📝 Added receiver to active requests: $receiverId');
    AppLogger.d('📊 [ConversationController] 📈 Active requests count: ${_activeRequests.length}');
    
    _setLoading(true);
    clearError();

    try {
      AppLogger.d('🚀 [ConversationController] 🌐 Starting conversation creation for receiver: $receiverId');
      AppLogger.d('📡 [ConversationController] 📶 Calling API: POST /conversations/');
      
      final conversation = await _messageService.createOrGetConversation(receiverId);
      
      if (_disposed) {
        AppLogger.d('⚠️ [ConversationController] 🗑️ Controller disposed, returning conversation without update');
        return conversation;
      }
      
      AppLogger.d('✅ [ConversationController] 🎉 Successfully created/retrieved conversation!');
      AppLogger.d('💬 [ConversationController] 🆔 Conversation ID: ${conversation.id}');
      AppLogger.d('👤 [ConversationController] 👥 Participant 1: ${conversation.participant1Id}');
      AppLogger.d('👤 [ConversationController] 👥 Participant 2: ${conversation.participant2Id}');
      AppLogger.d('👤 [ConversationController] 👨 Other user: ${conversation.otherUser.name}');
      
      return conversation;
    } catch (e) {
      if (_disposed) rethrow;
      
      AppLogger.d('❌ [ConversationController] 💥 Error creating/getting conversation');
      AppLogger.d('🔥 [ConversationController] 📋 Error details: $e');
      
      // Use centralized error handling
      final userMessage = ConversationErrorHandler.handleConversationError(
        error: e,
        source: 'ConversationController',
      );
      _setError(userMessage);
      rethrow;
    } finally {
      _activeRequests.remove(receiverId);
      AppLogger.d('🧹 [ConversationController] 🗑️ Removed receiver from active requests: $receiverId');
      AppLogger.d('📊 [ConversationController] 📉 Active requests count: ${_activeRequests.length}');
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
      AppLogger.d('❌ [ConversationController] ⚠️ Context is not mounted');
      throw Exception('Context is not mounted');
    }

    try {
      AppLogger.d('🧭 [ConversationController] 🚀 Starting navigation flow');
      AppLogger.d('👤 [ConversationController] 🎯 Target user: $receiverName ($receiverId)');
      if (receiverProfileImage != null) {
        AppLogger.d('🖼️ [ConversationController] 📸 Profile image: $receiverProfileImage');
      } else {
        AppLogger.d('🖼️ [ConversationController] ❌ No profile image provided');
      }
      
      AppLogger.d('📡 [ConversationController] 🌐 Creating/getting conversation...');
      // Create or get conversation
      final conversation = await createOrGetConversation(receiverId);
      
      if (!context.mounted) {
        AppLogger.d('⚠️ [ConversationController] ❌ Context unmounted after API call');
        throw Exception('Context is no longer mounted');
      }
      
      AppLogger.d('📊 [ConversationController] 📝 Checking MessageProvider for existing conversation');
      // Add conversation to MessageProvider if not already present
      final messageProvider = context.read<MessageProvider>();
      final existingConversation = messageProvider.getConversationById(conversation.id);
      
      if (existingConversation == null) {
        AppLogger.d('➕ [ConversationController] 🆕 Adding new conversation to MessageProvider');
        AppLogger.d('💬 [ConversationController] 🆔 Conversation ID: ${conversation.id}');
        messageProvider.addConversation(conversation);
        AppLogger.d('✅ [ConversationController] ✔️ Conversation added to provider');
      } else {
        AppLogger.d('✅ [ConversationController] 💬 Conversation already exists in provider');
        AppLogger.d('🔄 [ConversationController] ⏭️ Skipping duplicate addition');
      }
      
      AppLogger.d('📱 [ConversationController] 🚀 Navigating to ChatScreen');
      AppLogger.d('🆔 [ConversationController] 💬 Conversation ID: ${conversation.id}');
      AppLogger.d('👤 [ConversationController] 👨 User name: $receiverName');
      AppLogger.d('🖼️ [ConversationController] 📸 Profile image: ${receiverProfileImage ?? "none"}');
      
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
      
      AppLogger.d('✅ [ConversationController] 🎉 Navigation completed successfully');
      return conversation;
    } catch (e) {
      AppLogger.d('❌ [ConversationController] 💥 Navigation failed');
      AppLogger.d('🔥 [ConversationController] 📋 Error: $e');
      
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

  /// Reset controller state
  void reset() {
    _isLoading = false;
    _error = null;
    _activeRequests.clear();
    _inFlightRequests.clear();
    AppLogger.d('🔄 [ConversationController] Controller state reset');
    _notify();
  }

  @override
  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    _activeRequests.clear();
    _inFlightRequests.clear();
    AppLogger.d('🗑️ [ConversationController] Controller disposed (cleared ${_activeRequests.length} active requests)');
    super.dispose();
  }
}
