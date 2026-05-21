import 'package:flutter/foundation.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageController extends ChangeNotifier {
  final MessageService _messageService;
  String conversationId;
  final String receiverUserId;
  final ValueChanged<String>? onConversationIdChanged;

  MessageController({
    required MessageService messageService,
    required this.conversationId,
    required this.receiverUserId,
    this.onConversationIdChanged,
  }) : _messageService = messageService;

  final List<MessageModel> _messages = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _disposed = false;
  bool _isRecoveringConversation = false;
  Future<void>? _activeFetch;
  String? _error;
  int _currentPage = 1;

  // Enhanced request tracking
  final Map<String, DateTime> _requestTimestamps = {};
  final Set<String> _lockedOperations = {};

  static const int _pageSize = 20;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get hasMessages => _messages.isNotEmpty;
  bool get hasError => _error != null;
  String? get error => _error;

  Future<void> fetchInitialMessages() async {
    const operationKey = 'fetchInitial';

    // Enhanced duplicate prevention with multiple checks
    if (_lockedOperations.contains(operationKey)) {
      debugPrint(
        '🔒 [MessageController] Operation locked: $operationKey for $conversationId',
      );
      return;
    }

    if (_activeFetch != null) {
      debugPrint(
        '⏳ [MessageController] Active fetch in progress for $conversationId',
      );
      return _activeFetch!;
    }

    if (_isInitialLoading) {
      debugPrint(
        '🔄 [MessageController] Already loading initial messages for $conversationId',
      );
      return;
    }

    // Lock operation and track request
    _lockedOperations.add(operationKey);
    _requestTimestamps[operationKey] = DateTime.now();

    _currentPage = 1;
    _hasMoreData = true;

    debugPrint(
      '🚀 [MessageController] Starting initial fetch for $conversationId',
    );

    _activeFetch = _fetchMessages(page: _currentPage, replace: true)
        .then((_) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          debugPrint(
            '✅ [MessageController] Initial fetch completed for $conversationId',
          );
        })
        .catchError((e) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          debugPrint(
            '❌ [MessageController] Initial fetch failed for $conversationId: $e',
          );
        });

    return _activeFetch!;
  }

  Future<void> loadMoreMessages() async {
    final operationKey = 'loadMore';

    // Enhanced duplicate prevention
    if (_lockedOperations.contains(operationKey)) {
      debugPrint(
        '🔒 [MessageController] Operation locked: $operationKey for $conversationId',
      );
      return;
    }

    if (_activeFetch != null || _isLoadingMore || !_hasMoreData) {
      debugPrint(
        '🔄 [MessageController] Load more skipped. active=${_activeFetch != null}, loadingMore=$_isLoadingMore, hasMore=$_hasMoreData',
      );
      return;
    }

    // Lock operation
    _lockedOperations.add(operationKey);
    _requestTimestamps[operationKey] = DateTime.now();

    debugPrint(
      '🚀 [MessageController] Starting load more for $conversationId (page ${_currentPage + 1})',
    );

    _activeFetch = _fetchMessages(page: _currentPage + 1, replace: false)
        .then((_) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          debugPrint(
            '✅ [MessageController] Load more completed for $conversationId',
          );
        })
        .catchError((e) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          debugPrint(
            '❌ [MessageController] Load more failed for $conversationId: $e',
          );
        });

    return _activeFetch!;
  }

  Future<void> retry() => fetchInitialMessages();

  void appendLocalMessage(MessageModel message) {
    if (_messages.any((m) => m.id == message.id)) {
      debugPrint('⚠️ Duplicate message skipped: ${message.id}');
      return;
    }

    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    debugPrint(
      '📝 MESSAGE ADDED => '
      'id=${message.id} '
      'text=${message.text}',
    );

    _notify();
  }

  /// Socket-ready entry point for future realtime updates.
  void addRealtimeMessage(
    Map<String, dynamic> payload, {
    String? currentUserId,
  }) {
    try {
      final message = MessageModel.fromJson(
        payload,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
      );
      
      // Check for duplicate before adding
      if (_messages.any((m) => m.id == message.id)) {
        debugPrint('🔒 [MessageController] Duplicate realtime message skipped: ${message.id}');
        return;
      }
      
      _upsertMessage(message);
      _notify();

      debugPrint(
        '📡 [MessageController] Realtime message added: ${message.id} for $conversationId',
      );
    } catch (e) {
      debugPrint('❌ [MessageController] Failed to add realtime message: $e');
    }
  }

  void removeMessages(Set<String> ids) {
    _messages.removeWhere((message) => ids.contains(message.id));
    _notify();

    debugPrint(
      '🗑️ [MessageController] Removed ${ids.length} messages for $conversationId',
    );
  }

  /// Delete a single message with optimistic UI update
  ///
  /// [messageId] - The ID of the message to delete
  /// Returns true if successful, false otherwise
  Future<bool> deleteMessage(String messageId) async {
    if (messageId.isEmpty) {
      debugPrint('⚠️ [MessageController] ❌ Empty message ID provided');
      return false;
    }

    debugPrint('🗑️ [MessageController] 🚀 Starting delete for message: $messageId');
    debugPrint('💬 [MessageController] 🆔 Conversation: $conversationId');

    // Store original message for rollback
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) {
      debugPrint('⚠️ [MessageController] ❌ Message not found in local state');
      return false;
    }

    final originalMessage = _messages[messageIndex];
    debugPrint('💾 [MessageController] 📝 Stored original message for rollback');

    // Optimistic UI update - remove immediately
    debugPrint('⚡ [MessageController] 🗑️ Optimistic delete - removing from UI');
    _messages.removeAt(messageIndex);
    _notify();
    debugPrint('✅ [MessageController] 👀 UI updated - message removed');

    try {
      debugPrint('📡 [MessageController] 🌐 Calling API to delete message...');
      final success = await _messageService.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
      );

      if (success) {
        debugPrint('✅ [MessageController] 🎉 Message deleted successfully from backend');
        debugPrint('📊 [MessageController] 📉 Total messages: ${_messages.length}');
        return true;
      } else {
        debugPrint('❌ [MessageController] ⚠️ Backend delete failed - rolling back');
        // Rollback - restore message
        _messages.insert(messageIndex, originalMessage);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _notify();
        debugPrint('🔄 [MessageController] ✅ Rollback complete - message restored');
        return false;
      }
    } catch (e) {
      debugPrint('💥 [MessageController] ❌ Error deleting message: $e');
      debugPrint('🔄 [MessageController] 🔙 Rolling back optimistic update...');

      // Rollback - restore message
      _messages.insert(messageIndex, originalMessage);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _notify();
      debugPrint('✅ [MessageController] 🔄 Rollback complete - message restored');

      rethrow;
    }
  }

  void replaceMessage(MessageModel message) {
    final index = _messages.indexWhere((item) => item.id == message.id);
    if (index == -1) return;
    
    _messages[index] = message;
    _notify();

    debugPrint('🔄 [MessageController] Message replaced: ${message.id}');
  }

  /// Send message via REST API with comprehensive logging
  /// Returns the sent message on success, null on failure
  Future<MessageModel?> sendMessage(String content) async {
    debugPrint(
      '[MessageController] 🚀 REST send START for conversation: $conversationId',
    );

    try {
      debugPrint('[MessageController] 🔑 Fetching current user ID...');
      final currentUserId = await TokenStorage.getCurrentUserId();
      debugPrint('[MessageController] 👤 Current user ID: $currentUserId');

      debugPrint(
        '[MessageController] 🌐 Calling MessageService.sendMessage...',
      );
      final sentMessage = await _messageService.sendMessage(
        conversationId: conversationId,
        content: content,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
      );

      if (sentMessage != null) {
        debugPrint(
          '[MessageController] ✅ REST send SUCCESS: message ID=${sentMessage.id}',
        );
        debugPrint(
          '[MessageController] 💾 Upserting message to local state...',
        );
        _upsertMessage(sentMessage);
        _notify();
        debugPrint('[MessageController] ✅ Message persisted locally');
      } else {
        debugPrint('[MessageController] ⚠️ REST send returned NULL');
      }

      return sentMessage;
    } catch (error) {
      if (_shouldRecoverConversation(error)) {
        debugPrint(
          '[MessageController] Recovering conversation after participant error during send...',
        );
        final recovered = await _recoverConversationId();
        if (recovered) {
          return sendMessage(content);
        }
      }

      debugPrint('[MessageController] ❌ REST send FAILED: $error');
      _setError(error.toString());
      rethrow;
    }
  }

  Future<void> _fetchMessages({
    required int page,
    required bool replace,
  }) async {
    if (conversationId.isEmpty) {
      _error = 'Conversation ID is missing';
      _activeFetch = null;
      _notify();
      return;
    }

    if (replace) {
      _setInitialLoading(true);
    } else {
      _setLoadingMore(true);
    }
    _setError(null);

    try {
      debugPrint(
        '📡 [MessageController] Fetch messages conversation=$conversationId page=$page replace=$replace',
      );

      final currentUserId = await TokenStorage.getCurrentUserId();
      final fetchedMessages = await _messageService.getMessages(
        conversationId: conversationId,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
        page: page,
      );

      if (_disposed) return;

      if (replace) {
        _messages
          ..clear()
          ..addAll(fetchedMessages);
      } else {
        // Deduplicate by message.id before adding
        for (final message in fetchedMessages) {
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
          }
        }
      }

      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _hasMoreData = fetchedMessages.length >= _pageSize;
      _currentPage = page;

      debugPrint(
        '🎉 [MessageController] Loaded ${fetchedMessages.length} messages. total=${_messages.length} for $conversationId',
      );
    } catch (error) {
      if (_disposed) return;
      if (replace && _shouldRecoverConversation(error)) {
        debugPrint(
          '[MessageController] Recovering conversation after participant error during fetch...',
        );
        final recovered = await _recoverConversationId();
        if (recovered && !_disposed) {
          await _fetchMessages(page: 1, replace: true);
          return;
        }
      }

      debugPrint('❌ [MessageController] Fetch messages failed: $error');
      _setError(error.toString());
    } finally {
      _activeFetch = null;
      _setInitialLoading(false);
      _setLoadingMore(false);
    }
  }

  void _upsertMessage(MessageModel message) {
    final index = _messages.indexWhere((item) => item.id == message.id);
    if (index == -1) {
      _messages.add(message);
    } else {
      _messages[index] = message;
    }
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void _setInitialLoading(bool value) {
    if (_isInitialLoading == value) return;
    _isInitialLoading = value;
    _notify();
  }

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) return;
    _isLoadingMore = value;
    _notify();
  }

  void _setError(String? value) {
    if (_error == value) return;
    _error = value;
    _notify();
  }

  bool _shouldRecoverConversation(Object error) {
    final message = error.toString().toLowerCase();
    return !_isRecoveringConversation &&
        receiverUserId.isNotEmpty &&
        message.contains('403') &&
        message.contains('participant');
  }

  Future<bool> _recoverConversationId() async {
    if (_isRecoveringConversation) return false;
    _isRecoveringConversation = true;
    try {
      final conversation = await _messageService.createOrGetConversation(
        receiverUserId,
      );
      if (conversation.id.isEmpty || conversation.id == conversationId) {
        return false;
      }

      conversationId = conversation.id;
      onConversationIdChanged?.call(conversation.id);
      _setError(null);
      debugPrint(
        '[MessageController] Recovered conversation ID: $conversationId',
      );
      return true;
    } catch (recoverError) {
      debugPrint(
        '[MessageController] Failed to recover conversation ID: $recoverError',
      );
      return false;
    } finally {
      _isRecoveringConversation = false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;

    // Clear all locks and requests
    _lockedOperations.clear();
    _requestTimestamps.clear();
    _activeFetch = null;

    debugPrint(
      '🗑️ [MessageController] Disposed for $conversationId (cleared ${_lockedOperations.length} locks)',
    );
    super.dispose();
  }

  /// Get controller statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'conversationId': conversationId,
      'messageCount': _messages.length,
      'isInitialLoading': _isInitialLoading,
      'isLoadingMore': _isLoadingMore,
      'hasMoreData': _hasMoreData,
      'hasError': _error != null,
      'currentPage': _currentPage,
      'lockedOperations': _lockedOperations.toList(),
      'requestTimestamps': _requestTimestamps.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
      'disposed': _disposed,
    };
  }
}
