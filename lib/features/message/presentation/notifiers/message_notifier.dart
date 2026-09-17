import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/core/services/socket_service.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';

import 'package:gruve_app/features/message/domain/entities/conversation_model.dart';
import 'package:gruve_app/features/message/data/datasource/message_service.dart';
import 'dart:developer' as developer;
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';

/// Immutable state for [MessageNotifier]: the full fetched conversation list
/// (including ones without a last message yet), loading/refresh/pagination
/// flags and the last error.
@immutable
class MessageState {
  const MessageState({
    this.allConversations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isDeletingConversation = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  final List<ConversationModel> allConversations;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isDeletingConversation;
  final String? error;
  final int currentPage;
  final bool hasMoreData;

  /// Renderable conversations — those with at least one message.
  List<ConversationModel> get conversations =>
      List.unmodifiable(allConversations.where((c) => c.hasLastMessage));

  bool get hasError => error != null;
  bool get hasConversations => conversations.isNotEmpty;
  int get conversationCount => conversations.length;

  int get totalUnreadCount => conversations.fold(
    0,
    (sum, conversation) => sum + conversation.unreadCount,
  );

  MessageState copyWith({
    List<ConversationModel>? allConversations,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isDeletingConversation,
    String? error,
    bool clearError = false,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return MessageState(
      allConversations: allConversations ?? this.allConversations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDeletingConversation:
          isDeletingConversation ?? this.isDeletingConversation,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

/// Replaces the previous `MessageProvider` (ChangeNotifier). Owns the
/// conversation list, pagination, socket-driven realtime patching and
/// unread-count bookkeeping synced to [TokenStorage].
class MessageNotifier extends Notifier<MessageState> {
  final MessageService _messageService = MessageService();
  final SocketService _socketService = SocketService();

  StreamSubscription? _socketSubscription;
  CancelToken? _cancelToken;
  DateTime? _lastFetchTime;

  final Map<String, Future<void>> _inFlightFetches = {};
  final Set<String> _seenRealtimeEventKeys = <String>{};
  Timer? _refreshDebounceTimer;

  static const int _pageSize = 20;

  @override
  MessageState build() {
    AppLogger.d('🏗️ [MessageNotifier] Notifier initialized');
    _initializeSocketListener();

    ref.onDispose(() {
      _refreshDebounceTimer?.cancel();
      _socketSubscription?.cancel();
      _socketSubscription = null;
      _cancelToken?.cancel('Notifier disposed');
      AppLogger.d(
        '🗑️ [MessageNotifier] Disposed and socket listener cancelled',
      );
    });

    return const MessageState();
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      AppLogger.d('🎧 [MessageNotifier] Socket listener already active');
      return;
    }

    AppLogger.d('🎧 [MessageNotifier] Socket listener initialized');

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
    final payload = nested is Map ? Map<String, dynamic>.from(nested) : data;

    // Extract text cleanly, supporting nested maps or simple strings
    String contentStr = '';
    final rawContent = payload['content'];
    if (rawContent is Map) {
      final contentMap = Map<String, dynamic>.from(rawContent);
      contentStr = SafeParsingHelpers.safeString(contentMap, const [
        'text',
        'message',
        'value',
      ], fallback: '');
    } else {
      contentStr = SafeParsingHelpers.safeString(payload, const [
        'content',
        'text',
        'message',
      ], fallback: '');
    }

    // Extract message kind cleanly
    String? messageKind;
    if (rawContent is Map) {
      messageKind = SafeParsingHelpers.safeNullableString(
        Map<String, dynamic>.from(rawContent),
        const ['type'],
      );
    }
    messageKind ??= SafeParsingHelpers.safeNullableString(payload, const [
      'message_kind',
      'messageKind',
    ]);

    final attachments = payload['attachments'];
    if (messageKind == null && attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        messageKind = Map<String, dynamic>.from(
          first,
        )['media_kind']?.toString();
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

    final conversations = [...state.allConversations];
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final currentUserId = TokenStorage.getCurrentUserIdSync();
    final senderId = SafeParsingHelpers.safeString(payload, const [
      'sender_id',
      'senderId',
    ], fallback: '');
    final isOutgoing =
        currentUserId != null &&
        senderId.isNotEmpty &&
        currentUserId.trim() == senderId.trim();

    final now = DateTime.now();
    final conversation = conversations[index];
    final updated = conversation.copyWith(
      lastMessage: LastMessage(
        content: contentStr,
        createdAt: now,
        messageKind: messageKind,
      ),
      hasLastMessage: true,
      updatedAt: now,
      unreadCount: isOutgoing
          ? conversation.unreadCount
          : conversation.unreadCount + 1,
    );

    conversations[index] = updated;
    unawaited(TokenStorage.setUnreadCount(conversationId, updated.unreadCount));
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(allConversations: conversations);
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

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Screen disposed');
    _cancelToken = null;
  }

  /// Get conversation by user ID (other user)
  ConversationModel? getConversationByUserId(String userId) {
    final normalizedUserId = userId.trim();
    try {
      return state.allConversations.firstWhere(
        (conversation) => conversation.otherUser.id.trim() == normalizedUserId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get conversation by ID
  ConversationModel? getConversationById(String id) {
    try {
      return state.allConversations.firstWhere(
        (conversation) => conversation.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear any existing error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void _setError(String? error) {
    if (state.error != error) {
      state = state.copyWith(error: error, clearError: error == null);
      AppLogger.d('❌ [MessageNotifier] Error state changed: $error');
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
        state.allConversations.isNotEmpty) {
      AppLogger.d(
        '✅ [MessageNotifier] Using cached conversations (age: ${DateTime.now().difference(_lastFetchTime!).inSeconds}s)',
      );
      return;
    }

    final fetchKey = '${refresh ? 'refresh' : 'page'}:$requestedPage';
    final inFlight = _inFlightFetches[fetchKey];
    if (inFlight != null) {
      AppLogger.d('⏳ [MessageNotifier] Joining in-flight fetch $fetchKey');
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
      '📡 [MessageNotifier] fetchConversations trigger=$reason '
      'page=$requestedPage refresh=$refresh',
    );

    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        hasMoreData: true,
        isRefreshing: true,
      );
    } else if (isPagination) {
      state = state.copyWith(isLoadingMore: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    clearError();

    try {
      final apiStart = DateTime.now();
      final fetched = await _messageService.getConversationList(
        forceRefresh: refresh,
        page: requestedPage,
        pageSize: _pageSize,
        cancelToken: _getCancelToken(),
      );
      final apiTime = DateTime.now().difference(apiStart);

      AppLogger.d(
        '📩 [MessageNotifier] API response received in ${apiTime.inMilliseconds}ms',
      );
      AppLogger.d(
        '📊 [MessageNotifier] API returned ${fetched.length} conversations',
      );

      final preserveLocalUnread = reason == 'background_refresh' || !refresh;

      List<ConversationModel> newConversations;
      bool hasMoreData = state.hasMoreData;

      if (refresh || !isPagination) {
        newConversations = _cleanConversations(
          fetched,
          preserveLocalUnread: preserveLocalUnread,
        );
        _lastFetchTime = DateTime.now();
      } else {
        final beforeCount = state.allConversations.length;
        newConversations = _cleanConversations([
          ...state.allConversations,
          ...fetched,
        ], preserveLocalUnread: preserveLocalUnread);
        final addedCount = newConversations.length - beforeCount;
        AppLogger.d(
          '📊 [MessageNotifier] Added $addedCount new conversations (${fetched.length - addedCount} duplicates/invalid skipped)',
        );
        if (isPagination && addedCount <= 0) {
          hasMoreData = false;
        }
        if (!isPagination) {
          _lastFetchTime = DateTime.now();
        }
      }

      // Sort conversations by updated_at (most recent first)
      final sortStart = DateTime.now();
      newConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final sortTime = DateTime.now().difference(sortStart);

      // Update pagination state
      hasMoreData = hasMoreData && fetched.length >= _pageSize;

      state = state.copyWith(
        allConversations: newConversations,
        hasMoreData: hasMoreData,
        currentPage: requestedPage + 1,
      );

      final totalTime = DateTime.now().difference(fetchStart);
      developer.log(
        '🌐 [PERF] MessageNotifier fetch: API ${apiTime.inMilliseconds}ms, Sort ${sortTime.inMilliseconds}ms, Total ${totalTime.inMilliseconds}ms',
        name: 'MessageNotifier',
      );

      AppLogger.d(
        '✅ [MessageNotifier] Fetch complete — total: ${newConversations.length} | totalUnread: ${state.totalUnreadCount} | hasMore: ${state.hasMoreData}',
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [MessageNotifier] fetchConversations cancelled');
        return;
      }
      AppLogger.d('💥 [MessageNotifier] Error fetching conversations: $e');
      _setError(e.toString());
    } finally {
      if (refresh) {
        state = state.copyWith(isRefreshing: false);
      } else if (isPagination) {
        state = state.copyWith(isLoadingMore: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Pull-to-refresh functionality
  Future<void> refreshConversations() async {
    AppLogger.d('🔄 [MessageNotifier] Refresh conversations requested');
    await fetchConversations(refresh: true, reason: 'manual_refresh');
  }

  /// Load more conversations (pagination)
  Future<void> loadMoreConversations({String reason = 'scroll'}) async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMoreData) {
      AppLogger.d(
        '⏸️ [MessageNotifier] Skipping load more reason=$reason - '
        'Loading: ${state.isLoading}, LoadingMore: ${state.isLoadingMore}, '
        'Refreshing: ${state.isRefreshing}, HasMore: ${state.hasMoreData}',
      );
      return;
    }

    await fetchConversations(
      refresh: false,
      page: state.currentPage,
      reason: reason,
    );
  }

  /// Mark a conversation as read
  ///
  /// [conversationId] - The ID of the conversation to mark as read
  /// Returns true if successful
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      final success = await _messageService.markConversationAsRead(
        conversationId,
      );

      if (success) {
        final conversations = [...state.allConversations];
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          conversations[index] = conversations[index].copyWith(unreadCount: 0);
          state = state.copyWith(allConversations: conversations);
          unawaited(TokenStorage.setUnreadCount(conversationId, 0));
        }
      }

      return success;
    } catch (e) {
      AppLogger.d(
        '💥 [MessageNotifier] Error marking conversation as read: $e',
      );
      return false;
    }
  }

  /// Delete a conversation
  ///
  /// [conversationId] - The ID of the conversation to delete
  /// Returns true if successful
  Future<bool> deleteConversation(String conversationId) async {
    state = state.copyWith(isDeletingConversation: true);

    try {
      final success = await _messageService.deleteConversation(
        conversationId,
        cancelToken: _getCancelToken(),
      );

      if (success) {
        state = state.copyWith(
          allConversations: state.allConversations
              .where((c) => c.id != conversationId)
              .toList(),
        );
      }

      return success;
    } catch (e) {
      AppLogger.d('💥 [MessageNotifier] Error deleting conversation: $e');
      _setError('Failed to delete conversation');
      return false;
    } finally {
      state = state.copyWith(isDeletingConversation: false);
    }
  }

  /// Update a single conversation (for socket updates)
  ///
  /// [conversation] - The updated conversation data
  void updateConversation(ConversationModel conversation) {
    try {
      final conversations = [...state.allConversations];
      final index = conversations.indexWhere((c) => c.id == conversation.id);

      if (index != -1) {
        conversations[index] = conversation;
      } else {
        conversations.insert(0, conversation);
      }

      unawaited(
        TokenStorage.setUnreadCount(conversation.id, conversation.unreadCount),
      );

      final cleaned = _cleanConversations(
        conversations,
        preserveLocalUnread: true,
      );
      cleaned.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(allConversations: cleaned);
    } catch (e) {
      AppLogger.d('💥 [MessageNotifier] Error updating conversation: $e');
    }
  }

  /// Add a new conversation (for socket updates)
  ///
  /// [conversation] - The new conversation to add
  void addConversation(ConversationModel conversation) {
    if (!_isRenderableConversation(conversation)) {
      AppLogger.d(
        '🚫 [MessageNotifier] Invalid conversation skipped: ${conversation.id}',
      );
      return;
    }

    final key = _conversationKey(conversation);
    if (state.allConversations.any((item) => _conversationKey(item) == key)) {
      AppLogger.d(
        '🔒 [MessageNotifier] Duplicate conversation skipped: ${conversation.id}',
      );
      return;
    }

    state = state.copyWith(
      allConversations: [conversation, ...state.allConversations],
    );
  }

  /// Remove a conversation locally (for socket updates)
  ///
  /// [conversationId] - The ID of the conversation to remove
  void removeConversation(String conversationId) {
    state = state.copyWith(
      allConversations: state.allConversations
          .where((c) => c.id != conversationId)
          .toList(),
    );
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
        unawaited(
          TokenStorage.setUnreadCount(conversation.id, targetUnreadCount),
        );
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

  /// Reset all message data on logout.
  void reset() {
    _refreshDebounceTimer?.cancel();
    _lastFetchTime = null;
    _inFlightFetches.clear();
    _seenRealtimeEventKeys.clear();
    state = const MessageState();
    AppLogger.d('🔄 [MessageNotifier] State reset');
  }
}

final messageNotifierProvider = NotifierProvider<MessageNotifier, MessageState>(
  MessageNotifier.new,
);
