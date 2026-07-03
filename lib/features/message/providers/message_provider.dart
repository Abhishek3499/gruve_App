import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:gruve_app/features/auth/token_storage.dart';

import '../models/conversation_model.dart';
import '../services/message_service.dart';
import 'dart:developer' as developer;
import 'package:gruve_app/core/utils/app_logger.dart';
import '../../../core/parsing/safe_parsing_helpers.dart';

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
      if (!_isMessageSocketEvent(data)) return;

      try {
        final conversationId = _extractConversationId(data);
        final eventKey = _realtimeEventKey(data, conversationId);
        if (!_seenRealtimeEventKeys.add(eventKey)) {
          return;
        }
        if (_seenRealtimeEventKeys.length > 200) {
          _seenRealtimeEventKeys.remove(_seenRealtimeEventKeys.first);
        }

        _patchConversationFromSocket(data, conversationId);
        _scheduleBackgroundRefresh();
      } catch (e) {
        AppLogger.d('💥 SOCKET LISTENER ERROR: $e');
      }
    });
  }

  bool _isMessageSocketEvent(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    if (type.isEmpty) return false;

    const ignored = {
      'connected',
      'presence_snapshot',
      'online_users',
      'user_online',
      'presence_online',
      'user_connected',
      'user_active',
      'user_offline',
      'presence_offline',
      'user_disconnected',
      'user_inactive',
      'presence_update',
      'user_presence',
      'user_status',
      'status_update',
      'user_status_changed',
      'pong',
      'ping',
      'error',
      'chat.send',
    };
    if (ignored.contains(type)) return false;

    if (type == 'message' || type.startsWith('chat.')) return true;
    if (type == 'new_message' || type == 'message_received') return true;

    final event = data['event']?.toString().toLowerCase() ?? '';
    return event.startsWith('message.') || event.startsWith('chat.');
  }

  void _patchConversationFromSocket(
    Map<String, dynamic> data,
    String conversationId,
  ) {
    if (conversationId.isEmpty) return;

    final nested = data['data'];
    final payload = nested is Map
        ? Map<String, dynamic>.from(nested)
        : data;

    // Extract text cleanly, supporting nested maps or simple strings
    String contentStr = '';
    final rawContent = payload['content'];
    if (rawContent is Map) {
      final contentMap = Map<String, dynamic>.from(rawContent);
      contentStr = SafeParsingHelpers.safeString(
        contentMap,
        const ['text', 'message', 'value'],
        fallback: '',
      );
    } else {
      contentStr = SafeParsingHelpers.safeString(
        payload,
        const ['content', 'text', 'message'],
        fallback: '',
      );
    }

    // Extract message kind cleanly
    String? messageKind;
    if (rawContent is Map) {
      messageKind = SafeParsingHelpers.safeNullableString(
        Map<String, dynamic>.from(rawContent),
        const ['type'],
      );
    }
    messageKind ??= SafeParsingHelpers.safeNullableString(
      payload,
      const ['message_kind', 'messageKind'],
    );

    final attachments = payload['attachments'];
    if (messageKind == null && attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        messageKind = Map<String, dynamic>.from(first)['media_kind']?.toString();
      }
    }

    final media = payload['media'];
    if (messageKind == null && media is Map) {
      messageKind = Map<String, dynamic>.from(media)['media_kind']?.toString();
    }

    // Default preview text for audio messages if no caption is provided
    if (messageKind?.toLowerCase() == 'audio' && contentStr.trim().isEmpty) {
      contentStr = 'Voice message';
    }

    if (contentStr.trim().isEmpty) return;

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final currentUserId = TokenStorage.getCurrentUserIdSync();
    final senderId = SafeParsingHelpers.safeString(
      payload,
      const ['sender_id', 'senderId'],
      fallback: '',
    );
    final isOutgoing = currentUserId != null &&
        senderId.isNotEmpty &&
        currentUserId.trim() == senderId.trim();

    final now = DateTime.now();
    final conversation = _conversations[index];
    final updated = conversation.copyWith(
      lastMessage: LastMessage(
        content: contentStr,
        createdAt: now,
        messageKind: messageKind,
      ),
      hasLastMessage: true,
      updatedAt: now,
      unreadCount: isOutgoing ? conversation.unreadCount : conversation.unreadCount + 1,
    );

    _conversations[index] = updated;
    unawaited(TokenStorage.setUnreadCount(conversationId, updated.unreadCount));
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  void _scheduleBackgroundRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      fetchConversations(refresh: true, reason: 'background_refresh');
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
  Timer? _refreshDebounceTimer;

  // Pagination support (for future implementation)
  int _currentPage = 1;
  bool _hasMoreData = true;
  static const int _pageSize = 20;

  // Getters
  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations.where((c) => c.hasLastMessage));
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get isDeletingConversation => _isDeletingConversation;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;

  /// Get conversations count
  int get conversationCount => conversations.length;

  /// Get total unread count across all conversations
  int get totalUnreadCount {
    return conversations.fold(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );
  }

  /// Check if there are any conversations
  bool get hasConversations => conversations.isNotEmpty;

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
  Future<void> fetchConversations({
    bool refresh = false,
    int? page,
    String reason = 'initial',
  }) async {
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
      reason: reason,
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
    required String reason,
  }) async {
    final fetchStart = DateTime.now();
    final isPagination = !refresh && requestedPage > 1;

    AppLogger.d(
      '📡 [MessageProvider] fetchConversations trigger=$reason '
      'page=$requestedPage refresh=$refresh',
    );

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

      final preserveLocalUnread = reason == 'background_refresh' || !refresh;

      if (refresh || !isPagination) {
        _conversations = _cleanConversations(conversations, preserveLocalUnread: preserveLocalUnread);
        _lastFetchTime = DateTime.now();
      } else {
        final beforeCount = _conversations.length;
        _conversations = _cleanConversations(
          [
            ..._conversations,
            ...conversations,
          ],
          preserveLocalUnread: preserveLocalUnread,
        );
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
    await fetchConversations(refresh: true, reason: 'manual_refresh');
  }

  /// Load more conversations (pagination)
  Future<void> loadMoreConversations({String reason = 'scroll'}) async {
    if (_isLoading || _isLoadingMore || _isRefreshing || !_hasMoreData) {
      AppLogger.d(
        '⏸️ [MessageProvider] Skipping load more reason=$reason - '
        'Loading: $_isLoading, LoadingMore: $_isLoadingMore, '
        'Refreshing: $_isRefreshing, HasMore: $_hasMoreData',
      );
      return;
    }

    AppLogger.d(
      '📡 [MessageProvider] loadMoreConversations trigger=$reason page=$_currentPage',
    );
    await fetchConversations(refresh: false, page: _currentPage, reason: reason);
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
          unawaited(TokenStorage.setUnreadCount(conversationId, 0));
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

      unawaited(TokenStorage.setUnreadCount(conversation.id, conversation.unreadCount));

      _conversations = _cleanConversations(_conversations, preserveLocalUnread: true);

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
    Iterable<ConversationModel> conversations, {
    bool preserveLocalUnread = false,
  }) {
    final deduped = <String, ConversationModel>{};

    for (final conversation in conversations) {
      if (!_isRenderableConversation(conversation)) continue;

      final key = _conversationKey(conversation);
      var updatedConversation = conversation;

      final persistedCount = TokenStorage.getUnreadCount(conversation.id);
      final localConv = getConversationById(conversation.id);
      final currentInMemoryCount = localConv?.unreadCount ?? 0;

      int targetUnreadCount = conversation.unreadCount;
      if (persistedCount > targetUnreadCount) {
        targetUnreadCount = persistedCount;
      }
      if (preserveLocalUnread && currentInMemoryCount > targetUnreadCount) {
        targetUnreadCount = currentInMemoryCount;
      }

      if (targetUnreadCount != conversation.unreadCount) {
        updatedConversation = conversation.copyWith(
          unreadCount: targetUnreadCount,
        );
        unawaited(TokenStorage.setUnreadCount(conversation.id, targetUnreadCount));
      }

      final existing = deduped[key];
      if (existing == null ||
          updatedConversation.updatedAt.isAfter(existing.updatedAt)) {
        deduped[key] = updatedConversation;
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
    _refreshDebounceTimer?.cancel();
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
    _refreshDebounceTimer?.cancel();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    AppLogger.d('🗑️ [MessageProvider] Disposed and socket listener cancelled');
    super.dispose();
  }
}
