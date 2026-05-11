import 'package:flutter/foundation.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageController extends ChangeNotifier {
  final MessageService _messageService;
  final String conversationId;
  final String receiverUserId;

  MessageController({
    required MessageService messageService,
    required this.conversationId,
    required this.receiverUserId,
  }) : _messageService = messageService;

  final List<MessageModel> _messages = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _disposed = false;
  Future<void>? _activeFetch;
  String? _error;
  int _currentPage = 1;

  static const int _pageSize = 20;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get hasMessages => _messages.isNotEmpty;
  bool get hasError => _error != null;
  String? get error => _error;

  Future<void> fetchInitialMessages() {
    if (_activeFetch != null) {
      debugPrint(
        '[MessageController] Duplicate initial fetch skipped for $conversationId',
      );
      return _activeFetch!;
    }

    _currentPage = 1;
    _hasMoreData = true;
    _activeFetch = _fetchMessages(page: _currentPage, replace: true);
    return _activeFetch!;
  }

  Future<void> loadMoreMessages() {
    if (_activeFetch != null || _isLoadingMore || !_hasMoreData) {
      debugPrint(
        '[MessageController] Load more skipped. active=${_activeFetch != null}, loadingMore=$_isLoadingMore, hasMore=$_hasMoreData',
      );
      return Future.value();
    }

    _activeFetch = _fetchMessages(page: _currentPage + 1, replace: false);
    return _activeFetch!;
  }

  Future<void> retry() => fetchInitialMessages();

  void appendLocalMessage(MessageModel message) {
    _upsertMessage(message);
    _notify();
  }

  /// Socket-ready entry point for future realtime updates.
  void addRealtimeMessage(Map<String, dynamic> payload, {String? currentUserId}) {
    final message = MessageModel.fromJson(
      payload,
      currentUserId: currentUserId,
      receiverUserId: receiverUserId,
    );
    _upsertMessage(message);
    _notify();
  }

  void removeMessages(Set<String> ids) {
    _messages.removeWhere((message) => ids.contains(message.id));
    _notify();
  }

  void replaceMessage(MessageModel message) {
    final index = _messages.indexWhere((item) => item.id == message.id);
    if (index == -1) return;
    _messages[index] = message;
    _notify();
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
        '[MessageController] Fetch messages conversation=$conversationId page=$page replace=$replace',
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
        for (final message in fetchedMessages) {
          _upsertMessage(message);
        }
      }

      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _hasMoreData = fetchedMessages.length >= _pageSize;
      _currentPage = page;

      debugPrint(
        '[MessageController] Loaded ${fetchedMessages.length} messages. total=${_messages.length}',
      );
    } catch (error) {
      if (_disposed) return;
      debugPrint('[MessageController] Fetch messages failed: $error');
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

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    debugPrint('[MessageController] Disposed for $conversationId');
    super.dispose();
  }
}
