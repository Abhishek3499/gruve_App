import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/services/socket_service.dart';

import '../models/message_model.dart';
import '../services/message_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class MessageController extends ChangeNotifier {
  final MessageService _messageService;
  final CancelToken _cancelToken = CancelToken();
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
  Timer? _readDebounceTimer;

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
      AppLogger.d(
        '🔒 [MessageController] Operation locked: $operationKey for $conversationId',
      );
      return;
    }

    if (_activeFetch != null) {
      AppLogger.d(
        '⏳ [MessageController] Active fetch in progress for $conversationId',
      );
      return _activeFetch!;
    }

    if (_isInitialLoading) {
      AppLogger.d(
        '🔄 [MessageController] Already loading initial messages for $conversationId',
      );
      return;
    }

    // Lock operation and track request
    _lockedOperations.add(operationKey);
    _requestTimestamps[operationKey] = DateTime.now();

    _currentPage = 1;
    _hasMoreData = true;

    AppLogger.d(
      '🚀 [MessageController] Starting initial fetch for $conversationId',
    );

    _activeFetch = _fetchMessages(page: _currentPage, replace: true)
        .then((_) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          AppLogger.d(
            '✅ [MessageController] Initial fetch completed for $conversationId',
          );
        })
        .catchError((e) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          AppLogger.d(
            '❌ [MessageController] Initial fetch failed for $conversationId: $e',
          );
        });

    return _activeFetch!;
  }

  Future<void> loadMoreMessages() async {
    final operationKey = 'loadMore';

    // Enhanced duplicate prevention
    if (_lockedOperations.contains(operationKey)) {
      AppLogger.d(
        '🔒 [MessageController] Operation locked: $operationKey for $conversationId',
      );
      return;
    }

    if (_activeFetch != null || _isLoadingMore || !_hasMoreData) {
      AppLogger.d(
        '🔄 [MessageController] Load more skipped. active=${_activeFetch != null}, loadingMore=$_isLoadingMore, hasMore=$_hasMoreData',
      );
      return;
    }

    // Lock operation
    _lockedOperations.add(operationKey);
    _requestTimestamps[operationKey] = DateTime.now();

    AppLogger.d(
      '🚀 [MessageController] Starting load more for $conversationId (page ${_currentPage + 1})',
    );

    _activeFetch = _fetchMessages(page: _currentPage + 1, replace: false)
        .then((_) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          AppLogger.d(
            '✅ [MessageController] Load more completed for $conversationId',
          );
        })
        .catchError((e) {
          _lockedOperations.remove(operationKey);
          _requestTimestamps.remove(operationKey);
          AppLogger.d(
            '❌ [MessageController] Load more failed for $conversationId: $e',
          );
        });

    return _activeFetch!;
  }

  Future<void> retry() => fetchInitialMessages();

  void appendLocalMessage(MessageModel message) {
    if (_messages.any((m) => m.id == message.id)) {
      AppLogger.d('⚠️ Duplicate message skipped: ${message.id}');
      return;
    }

    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    AppLogger.d(
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
        AppLogger.d('🔒 [MessageController] Duplicate realtime message skipped: ${message.id}');
        return;
      }
      
      _upsertMessage(message);
      _notify();

      AppLogger.d(
        '📡 [MessageController] Realtime message added: ${message.id} for $conversationId',
      );
    } catch (e) {
      AppLogger.d('❌ [MessageController] Failed to add realtime message: $e');
    }
  }

  void removeMessages(Set<String> ids) {
    _messages.removeWhere((message) => ids.contains(message.id));
    _notify();

    AppLogger.d(
      '🗑️ [MessageController] Removed ${ids.length} messages for $conversationId',
    );
  }

  /// Delete a single message with optimistic UI update
  ///
  /// [messageId] - The ID of the message to delete
  /// Returns true if successful, false otherwise
  Future<bool> deleteMessage(String messageId) async {
    if (messageId.isEmpty) {
      AppLogger.d('⚠️ [MessageController] ❌ Empty message ID provided');
      return false;
    }

    AppLogger.d('🗑️ [MessageController] 🚀 Starting delete for message: $messageId');
    AppLogger.d('💬 [MessageController] 🆔 Conversation: $conversationId');

    // Store original message for rollback
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) {
      AppLogger.d('⚠️ [MessageController] ❌ Message not found in local state');
      return false;
    }

    final originalMessage = _messages[messageIndex];
    AppLogger.d('💾 [MessageController] 📝 Stored original message for rollback');

    // Optimistic UI update - remove immediately
    AppLogger.d('⚡ [MessageController] 🗑️ Optimistic delete - removing from UI');
    _messages.removeAt(messageIndex);
    _notify();
    AppLogger.d('✅ [MessageController] 👀 UI updated - message removed');

    try {
      AppLogger.d('📡 [MessageController] 🌐 Calling API to delete message...');
      final success = await _messageService.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
        cancelToken: _cancelToken,
      );

      if (success) {
        AppLogger.d('✅ [MessageController] 🎉 Message deleted successfully from backend');
        AppLogger.d('📊 [MessageController] 📉 Total messages: ${_messages.length}');
        return true;
      } else {
        AppLogger.d('❌ [MessageController] ⚠️ Backend delete failed - rolling back');
        // Rollback - restore message
        _messages.insert(messageIndex, originalMessage);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _notify();
        AppLogger.d('🔄 [MessageController] ✅ Rollback complete - message restored');
        return false;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageController] deleteMessage cancelled');
        return false;
      }
      AppLogger.d('💥 [MessageController] ❌ Error deleting message: $e');
      AppLogger.d('🔄 [MessageController] 🔙 Rolling back optimistic update...');

      // Rollback - restore message
      _messages.insert(messageIndex, originalMessage);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _notify();
      AppLogger.d('✅ [MessageController] 🔄 Rollback complete - message restored');

      rethrow;
    }
  }

  void replaceMessage(MessageModel message) {
    final index = _messages.indexWhere((item) => item.id == message.id);
    if (index == -1) return;
    
    _messages[index] = message;
    _notify();

    AppLogger.d('🔄 [MessageController] Message replaced: ${message.id}');
  }

  void markMessageAsFailed(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        status: MessageStatus.failed,
      );
      _notify();
      AppLogger.d('❌ [MessageController] Message marked as failed: $messageId');
    }
  }

  void handleMessageDelivered(String messageId) {
    var index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      // Locate the oldest local optimistic message
      index = _messages.indexWhere((m) => m.id.startsWith('local-'));
    }

    if (index != -1) {
      final currentMsg = _messages[index];
      // Only upgrade if current status is less than delivered (i.e. is sent)
      if (currentMsg.status == MessageStatus.sent) {
        _messages[index] = currentMsg.copyWith(
          id: messageId,
          status: MessageStatus.delivered,
          isRead: false,
        );
        _notify();
        AppLogger.d('📡 [MessageController] Message delivered status updated: $messageId');
      }
    }
  }

  void handleMessagesRead(List<String>? messageIds) {
    var changed = false;
    if (messageIds == null || messageIds.isEmpty) {
      // Mark all outgoing messages as read
      for (var i = 0; i < _messages.length; i++) {
        if (_messages[i].isSent && _messages[i].status != MessageStatus.read) {
          _messages[i] = _messages[i].copyWith(
            status: MessageStatus.read,
            isRead: true,
          );
          changed = true;
        }
      }
    } else {
      for (final id in messageIds) {
        var index = _messages.indexWhere((m) => m.id == id);
        if (index == -1) {
          // Fallback: Locate the oldest local optimistic message
          index = _messages.indexWhere((m) => m.id.startsWith('local-'));
        }

        if (index != -1) {
          final currentMsg = _messages[index];
          if (currentMsg.status != MessageStatus.read) {
            _messages[index] = currentMsg.copyWith(
              id: id,
              status: MessageStatus.read,
              isRead: true,
            );
            changed = true;
          }
        }
      }
    }
    if (changed) {
      _notify();
      AppLogger.d('📡 [MessageController] Message read statuses updated for: $messageIds');
    }
  }

  Future<void> markAsRead() async {
    if (conversationId.isEmpty) return;

    final eventData = {
      'type': 'message.read',
      'conversation_id': conversationId,
    };

    final socketService = SocketService();
    if (socketService.isConnected) {
      AppLogger.d('📡 [MessageController] Sending message.read over WebSocket');
      final success = socketService.sendEvent(eventData);
      if (success) return;
    }

    // Fallback: REST API
    AppLogger.d('📡 [MessageController] WebSocket unavailable. Calling REST markAsRead fallback.');
    try {
      await _messageService.markConversationAsRead(conversationId);
    } catch (e) {
      AppLogger.d('❌ [MessageController] REST fallback markAsRead failed: $e');
    }
  }

  void markAsReadDebounced() {
    if (_readDebounceTimer?.isActive ?? false) {
      _readDebounceTimer!.cancel();
    }
    _readDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      markAsRead();
    });
  }

  /// Send message via REST API with comprehensive logging
  /// Returns the sent message on success, null on failure
  Future<MessageModel?> sendMessage(String content) async {
    AppLogger.d(
      '[MessageController] 🚀 REST send START for conversation: $conversationId',
    );

    try {
      AppLogger.d('[MessageController] 🔑 Fetching current user ID...');
      final currentUserId = await TokenStorage.getCurrentUserId();
      AppLogger.d('[MessageController] 👤 Current user ID: $currentUserId');

      AppLogger.d(
        '[MessageController] 🌐 Calling MessageService.sendMessage...',
      );
      final sentMessage = await _messageService.sendMessage(
        conversationId: conversationId,
        content: content,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
        cancelToken: _cancelToken,
      );

      if (sentMessage != null) {
        AppLogger.d(
          '[MessageController] ✅ REST send SUCCESS: message ID=${sentMessage.id}',
        );
        AppLogger.d(
          '[MessageController] 💾 Upserting message to local state...',
        );
        _upsertMessage(sentMessage);
        _notify();
        AppLogger.d('[MessageController] ✅ Message persisted locally');
      } else {
        AppLogger.d('[MessageController] ⚠️ REST send returned NULL');
      }

      return sentMessage;
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        AppLogger.d('🚫 [MessageController] sendMessage cancelled');
        return null;
      }
      if (_shouldRecoverConversation(error)) {
        AppLogger.d(
          '[MessageController] Recovering conversation after participant error during send...',
        );
        final recovered = await _recoverConversationId();
        if (recovered) {
          return sendMessage(content);
        }
      }

      AppLogger.d('[MessageController] ❌ REST send FAILED: $error');
      _setError(error.toString());
      rethrow;
    }
  }

  Future<void> _fetchMessages({
    required int page,
    required bool replace,
  }) async {
    if (replace) {
      _setInitialLoading(true);
    } else {
      _setLoadingMore(true);
    }
    _setError(null);

    try {
      if (conversationId.isEmpty) {
        if (receiverUserId.isEmpty) {
          throw Exception('Receiver user ID is missing');
        }
        AppLogger.d('📡 [MessageController] Conversation ID is empty, fetching/creating from backend...');
        final conversation = await _messageService.createOrGetConversation(
          receiverUserId,
          cancelToken: _cancelToken,
        );
        conversationId = conversation.id;
        onConversationIdChanged?.call(conversation.id);
        AppLogger.d('📡 [MessageController] Conversation ID resolved: $conversationId');
      }

      AppLogger.d(
        '📡 [MessageController] Fetch messages conversation=$conversationId page=$page replace=$replace',
      );

      final currentUserId = await TokenStorage.getCurrentUserId();
      final fetchedMessages = await _messageService.getMessages(
        conversationId: conversationId,
        currentUserId: currentUserId,
        receiverUserId: receiverUserId,
        page: page,
        cancelToken: _cancelToken,
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

      AppLogger.d(
        '🎉 [MessageController] Loaded ${fetchedMessages.length} messages. total=${_messages.length} for $conversationId',
      );
    } catch (error) {
      if (_disposed) return;
      if (error is DioException && CancelToken.isCancel(error)) {
        AppLogger.d('🚫 [MessageController] fetchMessages cancelled');
        return;
      }
      if (replace && _shouldRecoverConversation(error)) {
        AppLogger.d(
          '[MessageController] Recovering conversation after participant error during fetch...',
        );
        final recovered = await _recoverConversationId();
        if (recovered && !_disposed) {
          await _fetchMessages(page: 1, replace: true);
          return;
        }
      }

      AppLogger.d('❌ [MessageController] Fetch messages failed: $error');
      _setError(error.toString());
    } finally {
      _activeFetch = null;
      _setInitialLoading(false);
      _setLoadingMore(false);
    }
  }

  void _upsertMessage(MessageModel message) {
    if (_messages.any((m) => m.id == message.id)) {
      AppLogger.d('🔒 [MessageController] Duplicate message by ID skipped in upsert: ${message.id}');
      return;
    }

    var index = _messages.indexWhere((item) => item.id == message.id);

    // If message is sent by me, try to match and replace local optimistic message
    if (index == -1 && message.isSent) {
      index = _messages.indexWhere((item) =>
          item.id.startsWith('local-') &&
          item.text.trim() == message.text.trim());
    }

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
        cancelToken: _cancelToken,
      );
      if (conversation.id.isEmpty || conversation.id == conversationId) {
        return false;
      }

      conversationId = conversation.id;
      onConversationIdChanged?.call(conversation.id);
      _setError(null);
      AppLogger.d(
        '[MessageController] Recovered conversation ID: $conversationId',
      );
      return true;
    } catch (recoverError) {
      AppLogger.d(
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
    _cancelToken.cancel('Screen disposed');

    _readDebounceTimer?.cancel();

    // Clear all locks and requests
    _lockedOperations.clear();
    _requestTimestamps.clear();
    _activeFetch = null;

    AppLogger.d(
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
