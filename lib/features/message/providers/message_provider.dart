import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/services/socket_service.dart';

import '../models/conversation_model.dart';
import '../services/message_service.dart';
import 'dart:developer' as developer;

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
    debugPrint('🏗️ [MessageProvider] Provider initialized');
    _initializeSocketListener();
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      debugPrint('🎧 [MessageProvider] Socket listener already active');
      return;
    }

    debugPrint('🎧 [MessageProvider] Socket listener initialized');

    _socketSubscription = _socketService.messageStream.listen((data) {
      debugPrint('🔥 FULL SOCKET DATA => $data');

      debugPrint('🔥 SOCKET MESSAGE RECEIVED: $data');

      try {
        final conversationId = _extractConversationId(data);
        final eventKey = _realtimeEventKey(data, conversationId);
        if (!_seenRealtimeEventKeys.add(eventKey)) {
          debugPrint('🔒 [MessageProvider] Duplicate realtime event skipped');
          return;
        }
        if (_seenRealtimeEventKeys.length > 200) {
          _seenRealtimeEventKeys.remove(_seenRealtimeEventKeys.first);
        }

        final index = _conversations.indexWhere((c) => c.id == conversationId);

        if (index != -1) {
          final oldConversation = _conversations[index];

          final updatedConversation = oldConversation.copyWith(
            updatedAt: DateTime.now(),
          );

          // Remove old position
          _conversations.removeAt(index);

          // Add updated conversation at top
          _conversations.insert(0, updatedConversation);

          debugPrint('✅ Realtime conversation updated');
        } else {
          debugPrint('⚠️ Conversation not found locally');
        }

        notifyListeners();

        debugPrint('🔄 UI UPDATED REALTIME');
      } catch (e) {
        debugPrint('💥 SOCKET LISTENER ERROR: $e');
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
  String? _error;
  DateTime? _lastFetchTime;
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
    debugPrint('🔍 [MessageProvider] 🔎 Searching conversation by userId: $userId');
    debugPrint('📊 [MessageProvider] 💬 Total conversations to search: ${_conversations.length}');
    
    try {
      final conversation = _conversations.firstWhere(
        (conversation) => conversation.otherUser.id == userId,
      );
      debugPrint('✅ [MessageProvider] 🎉 Conversation found!');
      debugPrint('💬 [MessageProvider] 🆔 Conversation ID: ${conversation.id}');
      debugPrint('👤 [MessageProvider] 👥 Other user: ${conversation.otherUser.name}');
      debugPrint('📨 [MessageProvider] 💭 Last message: ${conversation.lastMessage.content}');
      return conversation;
    } catch (e) {
      debugPrint('❌ [MessageProvider] 🚫 No conversation found with userId: $userId');
      debugPrint('📊 [MessageProvider] 📉 Searched through ${_conversations.length} conversations');
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
      debugPrint('⏳ [MessageProvider] Loading state changed: $loading');
      notifyListeners();
    }
  }

  /// Set loading state for pagination.
  void _setLoadingMore(bool loadingMore) {
    if (_isLoadingMore != loadingMore) {
      _isLoadingMore = loadingMore;
      debugPrint(
        '⬇️ [MessageProvider] Loading more state changed: $loadingMore',
      );
      notifyListeners();
    }
  }

  /// Set loading state for refresh
  void _setRefreshing(bool refreshing) {
    if (_isRefreshing != refreshing) {
      _isRefreshing = refreshing;
      debugPrint('🔄 [MessageProvider] Refresh state changed: $refreshing');
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      debugPrint('❌ [MessageProvider] Error state changed: $error');
      notifyListeners();
    }
  }

  /// Fetch conversations from API
  ///
  /// [refresh] - If true, will clear existing data and fetch fresh data
  /// [page] - Page number for pagination (default: 1)
  Future<void> fetchConversations({bool refresh = false, int? page}) async {
    // Check cache validity - reduce cache time for better freshness
    if (!refresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 2) &&
        _conversations.isNotEmpty) {
      debugPrint('✅ [MessageProvider] Using cached conversations (age: ${DateTime.now().difference(_lastFetchTime!).inSeconds}s)');
      return;
    }

    final requestedPage = page ?? 1;
    final fetchKey = '${refresh ? 'refresh' : 'page'}:$requestedPage';
    final inFlight = _inFlightFetches[fetchKey];
    if (inFlight != null) {
      debugPrint('⏳ [MessageProvider] Joining in-flight fetch $fetchKey');
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
      debugPrint(
        '📡 [MessageProvider] Fetching conversations - Page: $_currentPage, Refresh: $refresh',
      );

      final apiStart = DateTime.now();
      final conversations = await _messageService.getConversationList(
        forceRefresh: refresh,
        page: requestedPage,
        pageSize: _pageSize,
      );
      final apiTime = DateTime.now().difference(apiStart);

      debugPrint(
        '📩 [MessageProvider] API response received in ${apiTime.inMilliseconds}ms',
      );
      debugPrint(
        '📊 [MessageProvider] API returned ${conversations.length} conversations',
      );

      if (conversations.isEmpty) {
        debugPrint('⚠️ [MessageProvider] API returned EMPTY conversation list');
      } else {
        final ids = conversations.map((c) => c.id).take(5).toList();
        final unreadList = conversations
            .take(5)
            .map((c) => '${c.id.substring(0, 6)}:unread=${c.unreadCount}')
            .toList();
        debugPrint('💬 [MessageProvider] conversationIDs (first 5): $ids');
        debugPrint('🔔 [MessageProvider] unreadCounts (first 5): $unreadList');
      }

      if (refresh || !isPagination) {
        _conversations = conversations;
        _lastFetchTime = DateTime.now();
      } else {
        // Deduplicate by conversation.id before appending
        final existingIds = _conversations.map((c) => c.id).toSet();
        final newConversations = conversations
            .where((c) => !existingIds.contains(c.id))
            .toList();
        _conversations.addAll(newConversations);
        debugPrint(
          '📊 [MessageProvider] Added ${newConversations.length} new conversations (${conversations.length - newConversations.length} duplicates skipped)',
        );
        if (isPagination && newConversations.isEmpty) {
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
      if (!refresh) {
        _currentPage = requestedPage + 1;
      }

      final totalTime = DateTime.now().difference(fetchStart);
      developer.log(
        '🌐 [PERF] MessageProvider fetch: API ${apiTime.inMilliseconds}ms, Sort ${sortTime.inMilliseconds}ms, Total ${totalTime.inMilliseconds}ms',
        name: 'MessageProvider',
      );

      debugPrint(
        '✅ [MessageProvider] Fetch complete — total: ${_conversations.length} | totalUnread: $totalUnreadCount | hasMore: $_hasMoreData',
      );
    } catch (e) {
      debugPrint('💥 [MessageProvider] Error fetching conversations: $e');
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
      
      debugPrint('🏁 [MessageProvider] Loading states cleared - isLoading: $_isLoading, isRefreshing: $_isRefreshing, isLoadingMore: $_isLoadingMore');
    }
  }

  /// Pull-to-refresh functionality
  Future<void> refreshConversations() async {
    debugPrint('🔄 [MessageProvider] Refresh conversations requested');
    await fetchConversations(refresh: true);
  }

  /// Load more conversations (pagination)
  Future<void> loadMoreConversations() async {
    if (_isLoading || _isLoadingMore || _isRefreshing || !_hasMoreData) {
      debugPrint(
        '⏸️ [MessageProvider] Skipping load more - Loading: $_isLoading, LoadingMore: $_isLoadingMore, Refreshing: $_isRefreshing, HasMore: $_hasMoreData',
      );
      return;
    }

    debugPrint('⬇️ [MessageProvider] Loading more conversations...');
    await fetchConversations(refresh: false, page: _currentPage);
  }

  /// Mark a conversation as read
  ///
  /// [conversationId] - The ID of the conversation to mark as read
  /// Returns true if successful
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      debugPrint(
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
          debugPrint(
            '✅ [MessageProvider] Successfully marked conversation as read locally',
          );
        }
      }

      return success;
    } catch (e) {
      debugPrint('💥 [MessageProvider] Error marking conversation as read: $e');
      return false;
    }
  }

  /// Delete a conversation
  ///
  /// [conversationId] - The ID of the conversation to delete
  /// Returns true if successful
  Future<bool> deleteConversation(String conversationId) async {
    try {
      debugPrint(
        '🗑️ [MessageProvider] Deleting conversation: $conversationId',
      );

      final success = await _messageService.deleteConversation(conversationId);

      if (success) {
        // Remove from local state
        _conversations.removeWhere((c) => c.id == conversationId);
        notifyListeners();
        debugPrint(
          '✅ [MessageProvider] Successfully deleted conversation locally',
        );
      }

      return success;
    } catch (e) {
      debugPrint('💥 [MessageProvider] Error deleting conversation: $e');
      return false;
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
        debugPrint(
          '🔄 [MessageProvider] Updated existing conversation: ${conversation.id}',
        );
      } else {
        // Add new conversation at the beginning
        _conversations.insert(0, conversation);
        debugPrint(
          '➕ [MessageProvider] Added new conversation: ${conversation.id}',
        );
      }

      // Sort to maintain order
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      notifyListeners();
    } catch (e) {
      debugPrint('💥 [MessageProvider] Error updating conversation: $e');
    }
  }

  /// Add a new conversation (for socket updates)
  ///
  /// [conversation] - The new conversation to add
  void addConversation(ConversationModel conversation) {
    if (_conversations.any((item) => item.id == conversation.id)) {
      debugPrint(
        '🔒 [MessageProvider] Duplicate conversation skipped: ${conversation.id}',
      );
      return;
    }
    _conversations.insert(0, conversation);
    notifyListeners();
    debugPrint(
      '➕ [MessageProvider] Added new conversation: ${conversation.id}',
    );
  }

  /// Remove a conversation locally (for socket updates)
  ///
  /// [conversationId] - The ID of the conversation to remove
  void removeConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    notifyListeners();
    debugPrint('➖ [MessageProvider] Removed conversation: $conversationId');
  }

  /// Reset provider state
  void reset() {
    _conversations.clear();
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isRefreshing = false;
    _currentPage = 1;
    _hasMoreData = true;
    _lastFetchTime = null;
    _inFlightFetches.clear();
    _seenRealtimeEventKeys.clear();
    notifyListeners();
    debugPrint('🔄 [MessageProvider] Provider state reset');
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    debugPrint('🗑️ [MessageProvider] Disposed and socket listener cancelled');
    super.dispose();
  }
}
