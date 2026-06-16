import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/services/socket_service.dart';

import '../models/conversation_model.dart';
import '../services/message_service.dart';
import 'dart:developer' as developer;
import 'package:gruve_app/core/utils/app_logger.dart';

/// Provider for managing conversation state
///
/// This provider handles:
/// - Loading state management
/// - Conversation list management
/// - API calls and error handling
/// - Real-time updates (socket-ready structure)
/// - Pagination support (future enhancement)
class MessageProvider extends ChangeNotifier {
  final MessageService _messageService;
  final SocketService _socketService = SocketService();

  StreamSubscription? _socketSubscription;

  MessageProvider(this._messageService) {
    AppLogger.d('🏗️ [MessageProvider] Provider initialized');
    _initializeSocketListener();
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      AppLogger.d('🎧 [MessageProvider] Socket listener already active');
      return;
    }

    AppLogger.d('🎧 [MessageProvider] Socket listener initialized');

    _socketSubscription = _socketService.messageStream.listen((data) {
      AppLogger.d('🔥 FULL SOCKET DATA => $data');

      AppLogger.d('🔥 SOCKET MESSAGE RECEIVED: $data');

      try {
        final conversationId = _extractConversationId(data);
        final eventKey = _realtimeEventKey(data, conversationId);
        if (!_seenRealtimeEventKeys.add(eventKey)) {
          AppLogger.d('🔒 [MessageProvider] Duplicate realtime event skipped');
          return;
        }
        if (_seenRealtimeEventKeys.length > 200) {
          _seenRealtimeEventKeys.remove(_seenRealtimeEventKeys.first);
        }

        AppLogger.d('🔄 [MessageProvider] Realtime message received - triggering auto-refresh');
        // Silently refresh conversations in background to update UI in real-time
        fetchConversations(refresh: true);
      } catch (e) {
        AppLogger.d('💥 SOCKET LISTENER ERROR: $e');
      }
    });
  }

  String _realtimeEventKey(Map<String, dynamic> data, dynamic conversationId) {
    final nested = data['data'];
    final nestedId = nested is Map ? nested['id'] : null;
    final messageId = data['message_id'] ?? data['id'] ?? nestedId ?? '';
    final timestamp = data['timestamp'] ?? data['created_at'] ?? '';
    return '$conversationId|$messageId|$timestamp|${data['type'] ?? ''}';
  }

  String _extractConversationId(Map<String, dynamic> data) {
    final direct = data['conversation_id'] ?? data['conversationId'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }

    final nested = data['data'];
    if (nested is Map) {
      final nestedId = nested['conversation_id'] ?? nested['conversationId'];
      if (nestedId != null && nestedId.toString().trim().isNotEmpty) {
        return nestedId.toString().trim();
      }
    }

    return '';
  }

  // State variables
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isDeletingConversation = false;
  String? _error;
  DateTime? _lastFetchTime;
  CancelToken? _cancelToken;

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Screen disposed');
    _cancelToken = null;
  }

  final Map<String, Future<void>> _inFlightFetches = {};
  final Set<String> _seenRealtimeEventKeys = <String>{};

  // Pagination support (for future implementation)
  int _currentPage = 1;
  bool _hasMoreData = true;
  static const int _pageSize = 20;

  // Getters
  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get isDeletingConversation => _isDeletingConversation;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;

  /// Get conversations count
  int get conversationCount => _conversations.length;

  /// Get total unread count across all conversations
  int get totalUnreadCount {
    return _conversations.fold(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );
  }

  /// Check if there are any conversations
  bool get hasConversations => _conversations.isNotEmpty;

  /// Get conversation by user ID (other user)
  ConversationModel? getConversationByUserId(String userId) {
    final normalizedUserId = userId.trim();
    AppLogger.d(
      '🔍 [MessageProvider] 🔎 Searching conversation by userId: $normalizedUserId',
    );
    AppLogger.d(
      '📊 [MessageProvider] 💬 Total conversations to search: ${_conversations.length}',
    );

    try {
      final conversation = _conversations.firstWhere(
        (conversation) => conversation.otherUser.id.trim() == normalizedUserId,
      );
      AppLogger.d('✅ [MessageProvider] 🎉 Conversation found!');
      AppLogger.d('💬 [MessageProvider] 🆔 Conversation ID: ${conversation.id}');
      AppLogger.d(
        '👤 [MessageProvider] 👥 Other user: ${conversation.otherUser.name}',
      );
      AppLogger.d(
        '📨 [MessageProvider] 💭 Last message: ${conversation.lastMessage.content}',
      );
      return conversation;
    } catch (e) {
      AppLogger.d(
        '❌ [MessageProvider] 🚫 No conversation found with userId: $userId',
      );
      AppLogger.d(
        '📊 [MessageProvider] 📉 Searched through ${_conversations.length} conversations',
      );
      return null;
    }
  }

  /// Get conversation by ID
  ConversationModel? getConversationById(String id) {
    try {
      return _conversations.firstWhere((conversation) => conversation.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear any existing error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Set loading state for initial load
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      AppLogger.d('⏳ [MessageProvider] Loading state changed: $loading');
      notifyListeners();
    }
  }

  /// Set loading state for pagination.
  void _setLoadingMore(bool loadingMore) {
    if (_isLoadingMore != loadingMore) {
      _isLoadingMore = loadingMore;
      AppLogger.d(
        '⬇️ [MessageProvider] Loading more state changed: $loadingMore',
      );
      notifyListeners();
    }
  }

  /// Set loading state for refresh
  void _setRefreshing(bool refreshing) {
    if (_isRefreshing != refreshing) {
      _isRefreshing = refreshing;
      AppLogger.d('🔄 [MessageProvider] Refresh state changed: $refreshing');
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      AppLogger.d('❌ [MessageProvider] Error state changed: $error');
      notifyListeners();
    }
  }

  /// Fetch conversations from API
  ///
  /// [refresh] - If true, will clear existing data and fetch fresh data
  /// [page] - Page number for pagination (default: 1)
  Future<void> fetchConversations({bool refresh = false, int? page}) async {
    final requestedPage = page ?? 1;
    final isFirstPage = requestedPage <= 1;

    // Check cache validity - reduce cache time for better freshness
    if (!refresh &&
        isFirstPage &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(minutes: 2) &&
        _conversations.isNotEmpty) {
      AppLogger.d(
        '✅ [MessageProvider] Using cached conversations (age: ${DateTime.now().difference(_lastFetchTime!).inSeconds}s)',
      );
      return;
    }

    final fetchKey = '${refresh ? 'refresh' : 'page'}:$requestedPage';
    final inFlight = _inFlightFetches[fetchKey];
    if (inFlight != null) {
      AppLogger.d('⏳ [MessageProvider] Joining in-flight fetch $fetchKey');
      return inFlight;
    }

    final future = _runFetchConversations(
      refresh: refresh,
      requestedPage: requestedPage,
    );
    _inFlightFetches[fetchKey] = future;
    try {
      return await future;
    } finally {
      _inFlightFetches.remove(fetchKey);
    }
  }

  Future<void> _runFetchConversations({
    required bool refresh,
    required int requestedPage,
  }) async {
    final fetchStart = DateTime.now();
    final isPagination = !refresh && requestedPage > 1;

    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _setRefreshing(true);
    } else if (isPagination) {
      _setLoadingMore(true);
    } else {
      _setLoading(true);
    }

    clearError();

    try {
      AppLogger.d(
        '📡 [MessageProvider] Fetching conversations - Page: $_currentPage, Refresh: $refresh',
      );

      final apiStart = DateTime.now();
      final conversations = await _messageService.getConversationList(
        forceRefresh: refresh,
        page: requestedPage,
        pageSize: _pageSize,
        cancelToken: _getCancelToken(),
      );
      final apiTime = DateTime.now().difference(apiStart);

      AppLogger.d(
        '📩 [MessageProvider] API response received in ${apiTime.inMilliseconds}ms',
      );
      AppLogger.d(
        '📊 [MessageProvider] API returned ${conversations.length} conversations',
      );

      if (conversations.isEmpty) {
        AppLogger.d('⚠️ [MessageProvider] API returned EMPTY conversation list');
      } else {
        final ids = conversations.map((c) => c.id).take(5).toList();
        final unreadList = conversations
            .take(5)
            .map((c) => '${c.id.substring(0, 6)}:unread=${c.unreadCount}')
            .toList();
        AppLogger.d('💬 [MessageProvider] conversationIDs (first 5): $ids');
        AppLogger.d('🔔 [MessageProvider] unreadCounts (first 5): $unreadList');
      }

      if (refresh || !isPagination) {
        _conversations = _cleanConversations(conversations);
        _lastFetchTime = DateTime.now();
      } else {
        final beforeCount = _conversations.length;
        _conversations = _cleanConversations([
          ..._conversations,
          ...conversations,
        ]);
        final addedCount = _conversations.length - beforeCount;
        AppLogger.d(
          '📊 [MessageProvider] Added $addedCount new conversations (${conversations.length - addedCount} duplicates/invalid skipped)',
        );
        if (isPagination && addedCount <= 0) {
          _hasMoreData = false;
        }
        if (!isPagination) {
          _lastFetchTime = DateTime.now();
        }
      }

      // Sort conversations by updated_at (most recent first)
      final sortStart = DateTime.now();
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final sortTime = DateTime.now().difference(sortStart);

      // Update pagination state
      _hasMoreData = _hasMoreData && conversations.length >= _pageSize;
      _currentPage = requestedPage + 1;

      final totalTime = DateTime.now().difference(fetchStart);
      developer.log(
        '🌐 [PERF] MessageProvider fetch: API ${apiTime.inMilliseconds}ms, Sort ${sortTime.inMilliseconds}ms, Total ${totalTime.inMilliseconds}ms',
        name: 'MessageProvider',
      );

      AppLogger.d(
        '✅ [MessageProvider] Fetch complete — total: ${_conversations.length} | totalUnread: $totalUnreadCount | hasMore: $_hasMoreData',
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageProvider] fetchConversations cancelled');
        return;
      }
      AppLogger.d('💥 [MessageProvider] Error fetching conversations: $e');
      _setError(e.toString());
    } finally {
      // Clear loading states properly
      if (refresh) {
        _setRefreshing(false);
      } else if (isPagination) {
        _setLoadingMore(false);
      } else {
        _setLoading(false);
      }

      AppLogger.d(
        '🏁 [MessageProvider] Loading states cleared - isLoading: $_isLoading, isRefreshing: $_isRefreshing, isLoadingMore: $_isLoadingMore',
      );
    }
  }

  /// Pull-to-refresh functionality
  Future<void> refreshConversations() async {
    AppLogger.d('🔄 [MessageProvider] Refresh conversations requested');
    await fetchConversations(refresh: true);
  }

  /// Load more conversations (pagination)
  Future<void> loadMoreConversations() async {
    if (_isLoading || _isLoadingMore || _isRefreshing || !_hasMoreData) {
      AppLogger.d(
        '⏸️ [MessageProvider] Skipping load more - Loading: $_isLoading, LoadingMore: $_isLoadingMore, Refreshing: $_isRefreshing, HasMore: $_hasMoreData',
      );
      return;
    }

    AppLogger.d('⬇️ [MessageProvider] Loading more conversations...');
    await fetchConversations(refresh: false, page: _currentPage);
  }

  /// Mark a conversation as read
  ///
  /// [conversationId] - The ID of the conversation to mark as read
  /// Returns true if successful
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      AppLogger.d(
        '👁️ [MessageProvider] Marking conversation as read: $conversationId',
      );

      final success = await _messageService.markConversationAsRead(
        conversationId,
      );

      if (success) {
        // Update local state
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final updatedConversation = _conversations[index].copyWith(
            unreadCount: 0,
          );
          _conversations[index] = updatedConversation;
          notifyListeners();
          AppLogger.d(
            '✅ [MessageProvider] Successfully marked conversation as read locally',
          );
        }
      }

      return success;
    } catch (e) {
      AppLogger.d('💥 [MessageProvider] Error marking conversation as read: $e');
      return false;
    }
  }

  /// Delete a conversation
  ///
  /// [conversationId] - The ID of the conversation to delete
  /// Returns true if successful
  Future<bool> deleteConversation(String conversationId) async {
    _isDeletingConversation = true;
    notifyListeners();

    try {
      AppLogger.d(
        '🗑️ [MessageProvider] Deleting conversation: $conversationId',
      );

      final success = await _messageService.deleteConversation(
        conversationId,
        cancelToken: _getCancelToken(),
      );

      if (success) {
        // Remove from local state
        _conversations.removeWhere((c) => c.id == conversationId);
        AppLogger.d(
          '✅ [MessageProvider] Successfully deleted conversation locally',
        );
      }

      return success;
    } catch (e) {
      AppLogger.d('💥 [MessageProvider] Error deleting conversation: $e');
      _setError('Failed to delete conversation');
      return false;
    } finally {
      _isDeletingConversation = false;
      notifyListeners();
    }
  }

  /// Update a single conversation (for socket updates)
  ///
  /// [conversation] - The updated conversation data
  void updateConversation(ConversationModel conversation) {
    try {
      final index = _conversations.indexWhere((c) => c.id == conversation.id);

      if (index != -1) {
        // Update existing conversation
        _conversations[index] = conversation;
        AppLogger.d(
          '🔄 [MessageProvider] Updated existing conversation: ${conversation.id}',
        );
      } else {
        // Add new conversation at the beginning
        _conversations.insert(0, conversation);
        AppLogger.d(
          '➕ [MessageProvider] Added new conversation: ${conversation.id}',
        );
      }

      _conversations = _cleanConversations(_conversations);

      // Sort to maintain order
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      notifyListeners();
    } catch (e) {
      AppLogger.d('💥 [MessageProvider] Error updating conversation: $e');
    }
  }

  /// Add a new conversation (for socket updates)
  ///
  /// [conversation] - The new conversation to add
  void addConversation(ConversationModel conversation) {
    if (!_isRenderableConversation(conversation)) {
      AppLogger.d(
        '🚫 [MessageProvider] Invalid conversation skipped: ${conversation.id}',
      );
      return;
    }

    final key = _conversationKey(conversation);
    if (_conversations.any((item) => _conversationKey(item) == key)) {
      AppLogger.d(
        '🔒 [MessageProvider] Duplicate conversation skipped: ${conversation.id}',
      );
      return;
    }
    _conversations.insert(0, conversation);
    notifyListeners();
    AppLogger.d(
      '➕ [MessageProvider] Added new conversation: ${conversation.id}',
    );
  }

  /// Remove a conversation locally (for socket updates)
  ///
  /// [conversationId] - The ID of the conversation to remove
  void removeConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    notifyListeners();
    AppLogger.d('➖ [MessageProvider] Removed conversation: $conversationId');
  }

  List<ConversationModel> _cleanConversations(
    Iterable<ConversationModel> conversations,
  ) {
    final deduped = <String, ConversationModel>{};

    for (final conversation in conversations) {
      if (!_isRenderableConversation(conversation)) continue;

      final key = _conversationKey(conversation);
      final existing = deduped[key];
      if (existing == null ||
          conversation.updatedAt.isAfter(existing.updatedAt)) {
        deduped[key] = conversation;
      }
    }

    return deduped.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  bool _isRenderableConversation(ConversationModel conversation) {
    final conversationId = conversation.id.trim();
    final userId = conversation.otherUser.id.trim();
    final name = conversation.otherUser.name.trim();

    if (conversationId.isEmpty || userId.isEmpty || name.isEmpty) {
      return false;
    }

    return name.toLowerCase() != 'unknown';
  }

  String _conversationKey(ConversationModel conversation) {
    final userId = conversation.otherUser.id.trim();
    if (userId.isNotEmpty) return 'user:$userId';
    return 'conversation:${conversation.id.trim()}';
  }

  /// Reset provider state
  void reset() {
    _conversations.clear();
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isRefreshing = false;
    _isDeletingConversation = false;
    _currentPage = 1;
    _hasMoreData = true;
    _lastFetchTime = null;
    _inFlightFetches.clear();
    _seenRealtimeEventKeys.clear();
    notifyListeners();
    AppLogger.d('🔄 [MessageProvider] Provider state reset');
  }

  @override
  void dispose() {
    cancelActiveRequests();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    AppLogger.d('🗑️ [MessageProvider] Disposed and socket listener cancelled');
    super.dispose();
  }
}
