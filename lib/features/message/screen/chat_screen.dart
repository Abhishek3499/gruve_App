import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:provider/provider.dart';

import '../../../services/socket_service.dart';
import '../../../features/auth/token_storage.dart';

import '../controllers/message_controller.dart';
import '../providers/message_provider.dart';
import '../models/conversation_model.dart';
import '../models/message_media_model.dart';
import '../models/message_reply_preview.dart';
import '../models/message_model.dart';
import '../models/reply_message_model.dart';
import '../services/message_service.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_popup_menu.dart';
import '../widgets/block/block_user_widget.dart';
import '../widgets/pinned_message_banner.dart';
import '../widgets/reply_preview_bar.dart';
import '../../../core/widgets/shimmer/chat_shimmer.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ChatScreen extends StatefulWidget {
  // New explicit parameters for direct user data passing
  final String? conversationId;
  final String? receiverId;
  final String? userName;
  final String? profileImage;

  // Legacy support for existing ConversationModel flow
  final dynamic userOrConversation;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.receiverId,
    this.userName,
    this.profileImage,
    this.userOrConversation,
  }) : assert(
         conversationId != null || receiverId != null || userOrConversation != null,
         'Either conversationId, receiverId, or userOrConversation must be provided',
       );

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final MessageController _messageController;
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();
  final TextEditingController _inputController = TextEditingController();
  final SocketService _socketService = SocketService();

  StreamSubscription? _socketSubscription;

  bool _isLoadingOlderMessages = false;
  bool _isUploadingMedia = false;
  bool _hasCompletedInitialScroll = false;
  String? _resolvedConversationId;
  String? _currentUserId;
  ReplyMessageModel? _activeReply;
  MessageModel? _editingMessage;
  MessageModel? _pinnedMessage;

  bool _showPopup = false;
  MessageModel? _popupMessage;
  double _popupMenuTop = 0;

  bool _isDeleteMode = false;
  final Set<String> _selectedMessageIds = {};

  bool get _isConversationModel =>
      widget.userOrConversation is ConversationModel;

  bool get _useExplicitData => widget.conversationId != null;

  String get _userName {
    final explicitName = widget.userName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    if (_isConversationModel) {
      return (widget.userOrConversation as ConversationModel).otherUserName;
    }

    // Handle Map object from MessageAvatar
    final dynamic userData = widget.userOrConversation;
    if (userData is Map) {
      return userData['name']?.toString() ?? 'Unknown';
    }

    return userData?.name?.toString() ?? 'Unknown';
  }

  String get _userId {
    final explicitId = widget.receiverId?.trim();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }

    if (_isConversationModel) {
      return (widget.userOrConversation as ConversationModel).otherUser.id;
    }

    // Handle Map object from MessageAvatar
    final dynamic userData = widget.userOrConversation;
    if (userData is Map) {
      return userData['id']?.toString() ?? '';
    }

    return userData?.id?.toString() ?? '';
  }

  String get _conversationId {
    if (_resolvedConversationId != null &&
        _resolvedConversationId!.isNotEmpty) {
      return _resolvedConversationId!;
    }

    // Priority 1: Explicit conversationId parameter
    if (_useExplicitData && widget.conversationId != null) {
      return widget.conversationId!;
    }

    // Priority 2: ConversationModel data
    if (_isConversationModel) {
      return (widget.userOrConversation as ConversationModel).id;
    }

    // Priority 3: Legacy user data
    try {
      final dynamic legacyUser = widget.userOrConversation;
      return legacyUser?.conversationId?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String? get _userAvatar {
    // Priority 1: Explicit profile image parameter
    if (widget.profileImage != null && widget.profileImage!.isNotEmpty) {
      return widget.profileImage;
    }

    if (_isConversationModel) {
      return (widget.userOrConversation as ConversationModel).otherUserAvatar;
    }

    // Handle Map object from MessageAvatar
    final dynamic userData = widget.userOrConversation;
    if (userData is Map) {
      return userData['profileImage']?.toString();
    }

    return userData?.profileImage?.toString();
  }

  @override
  void initState() {
    super.initState();

    // Socket connection is now managed automatically without heartbeat context

    AppLogger.d(
      '[ChatScreen] init user=$_userName conversation=$_conversationId',
    );

    _messageController = MessageController(
      messageService: MessageService(),
      conversationId: _conversationId,
      receiverUserId: _userId,
      onConversationIdChanged: (conversationId) {
        _resolvedConversationId = conversationId;
        AppLogger.d(
          '[ChatScreen] Active conversation recovered: $conversationId',
        );
      },
    )..addListener(_onMessageControllerTick);
    _scrollController.addListener(_onMessageScroll);
    _initializeSocketListener();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _currentUserId = await TokenStorage.getCurrentUserId();
      if (!mounted) return;
      final blockProvider = context.read<BlockProvider>();
      try {
        await blockProvider.fetchBlockedUsers();
        if (!mounted) return;
        final isBlocked = blockProvider.blockedUsers.any(
          (user) => user.userId == _userId,
        );
        blockProvider.setBlockState(_userId, isBlocked);
        AppLogger.d(
          '🔒 [ChatScreen] Block state synced from backend = $isBlocked',
        );
      } catch (e) {
        AppLogger.d('⚠️ [ChatScreen] Failed to sync block state: $e');
      }
    });
    // Requirement: the messages API is called only after ChatScreen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppLogger.d('[ChatScreen] Fetch messages requested for $_conversationId');
      _hasCompletedInitialScroll = false;
      _messageController.fetchInitialMessages();
      _messageController.markAsReadDebounced();
    });
  }

  void _onMessageScroll() {
    if (!_scrollController.hasClients ||
        _messageController.isInitialLoading) {
      return;
    }

    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading:
          _isLoadingOlderMessages ||
          _messageController.isLoadingMore,
      hasMore: _messageController.hasMoreData,
    )) {
      return;
    }

    _loadOlderMessages();
  }

  Future<void> _loadOlderMessages() async {
    if (!_scrollController.hasClients ||
        _isLoadingOlderMessages ||
        _messageController.isLoadingMore ||
        !_messageController.hasMoreData) {
      return;
    }

    _isLoadingOlderMessages = true;

    await _messageController.loadMoreMessages();

    if (mounted) {
      setState(() {
        _isLoadingOlderMessages = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationId != oldWidget.conversationId ||
        widget.userOrConversation != oldWidget.userOrConversation) {
      // Socket connection context is no longer needed for heartbeats
    }
  }

  /// Scroll-only reactions — message list rebuilds via [ListenableBuilder].
  void _onMessageControllerTick() {
    if (!mounted) return;

    if (!_messageController.isInitialLoading &&
        !_messageController.hasError &&
        _messageController.hasMessages &&
        !_hasCompletedInitialScroll) {
      _hasCompletedInitialScroll = true;
      _scrollToBottom(animated: true);
    }

    // Optimistically update conversation details in MessageProvider for instant refresh on back navigation
    if (!_messageController.isInitialLoading &&
        !_messageController.hasError &&
        _messageController.hasMessages) {
      final conversationId = _messageController.conversationId;
      if (conversationId.isNotEmpty) {
        final lastMsg = _messageController.messagesNewestFirst.first;
        final messageProvider = context.read<MessageProvider>();
        final existingConversation = messageProvider.getConversationById(conversationId);
        
        if (existingConversation != null) {
          final updated = existingConversation.copyWith(
            lastMessage: LastMessage(
              content: lastMsg.text.isEmpty && lastMsg.hasMedia
                  ? (lastMsg.mediaKind == 'audio' ? 'Voice message' : lastMsg.mediaKind ?? 'Media')
                  : lastMsg.text,
              createdAt: lastMsg.timestamp,
              messageKind: lastMsg.mediaKind,
            ),
            hasLastMessage: true,
            updatedAt: lastMsg.timestamp,
            unreadCount: 0,
          );
          messageProvider.updateConversation(updated);
        } else {
          final newConversation = ConversationModel(
            id: conversationId,
            otherUser: OtherUser(
              id: _userId,
              name: _userName,
              avatar: _userAvatar,
            ),
            lastMessage: LastMessage(
              content: lastMsg.text.isEmpty && lastMsg.hasMedia
                  ? (lastMsg.mediaKind == 'audio' ? 'Voice message' : lastMsg.mediaKind ?? 'Media')
                  : lastMsg.text,
              createdAt: lastMsg.timestamp,
              messageKind: lastMsg.mediaKind,
            ),
            hasLastMessage: true,
            updatedAt: lastMsg.timestamp,
            unreadCount: 0,
          );
          messageProvider.updateConversation(newConversation);
        }
      }
    }
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0.0);
      }
    });
  }

  bool _isChatSocketEvent(String? type, String? event) {
    if (type == null || type.isEmpty) return false;
    final normalized = type.toLowerCase();
    if (normalized == 'message') return true;
    if (normalized.startsWith('message.')) return true;
    if (normalized.startsWith('chat.') && normalized != 'chat.send') {
      return true;
    }
    if (normalized == 'new_message' || normalized == 'message_received') {
      return true;
    }
    if (event != null &&
        (event.startsWith('message.') || event.startsWith('chat.'))) {
      return true;
    }
    return false;
  }

  bool _isDeliveryEvent(String? type, String? event) {
    final normalizedType = type?.toLowerCase() ?? '';
    final normalizedEvent = event?.toLowerCase() ?? '';
    return normalizedEvent == 'message.delivered' ||
        normalizedType == 'message.delivered' ||
        normalizedType == 'chat.delivered';
  }

  bool _isReadEvent(String? type, String? event) {
    final normalizedType = type?.toLowerCase() ?? '';
    final normalizedEvent = event?.toLowerCase() ?? '';
    return normalizedEvent == 'message.read' ||
        normalizedType == 'message.read' ||
        normalizedType == 'chat.read';
  }

  bool _isEditedEvent(String? type, String? event) {
    final normalizedType = type?.toLowerCase() ?? '';
    final normalizedEvent = event?.toLowerCase() ?? '';
    return normalizedEvent == 'message.edited' ||
        normalizedType == 'message.edited' ||
        normalizedType == 'chat.edited';
  }

  Map<String, dynamic> _extractMessagePayload(Map<String, dynamic> data) {
    final nested = data['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    final payload = data['payload'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return Map<String, dynamic>.from(data);
  }

  void _handleIncomingSocketMessage(Map<String, dynamic> data) {
    final event = data['event']?.toString();
    final type = data['type']?.toString().toLowerCase();

    if (!_isChatSocketEvent(type, event)) return;

    if (_isDeliveryEvent(type, event)) {
      final messageData = _extractMessagePayload(data);
      final messageId =
          messageData['message_id']?.toString() ??
          messageData['id']?.toString();
      if (messageId != null && messageId.isNotEmpty) {
        final content =
            messageData['content']?.toString() ??
            messageData['text']?.toString();
        _messageController.handleMessageDelivered(
          messageId,
          content: content,
        );
      }
      return;
    }

    if (_isReadEvent(type, event)) {
      final messageData = _extractMessagePayload(data);
      final messageIds =
          (messageData['message_ids'] as List?)
              ?.map((e) => e.toString())
              .toList();
      _messageController.handleMessagesRead(messageIds);
      return;
    }

    if (_isEditedEvent(type, event)) {
      final messageData = _extractMessagePayload(data);
      final incomingConversationId = _extractConversationId(data);
      if (incomingConversationId.isNotEmpty &&
          incomingConversationId != _conversationId) {
        return;
      }
      _messageController.handleMessageEdited(messageData);
      return;
    }

    final messageData = _extractMessagePayload(data);
    final incomingConversationId = _extractConversationId(data);

    if (incomingConversationId.isNotEmpty && _conversationId.isEmpty) {
      final senderIdStr =
          (messageData['sender_id'] ?? messageData['senderId'] ?? '')
              .toString();
      final receiverIdStr =
          (messageData['receiver_id'] ?? messageData['receiverId'] ?? '')
              .toString();
      final isRelevant =
          senderIdStr == _userId ||
          receiverIdStr == _userId ||
          senderIdStr == _currentUserId ||
          receiverIdStr == _currentUserId;

      if (isRelevant) {
        _resolvedConversationId = incomingConversationId;
        _messageController.conversationId = incomingConversationId;
        _messageController.onConversationIdChanged?.call(
          incomingConversationId,
        );
      }
    }

    if (incomingConversationId.isNotEmpty &&
        incomingConversationId != _conversationId) {
      return;
    }

    final hasMessageText =
        messageData['content'] != null ||
        messageData['text'] != null ||
        messageData['message'] != null;
    final looksLikeMessage =
        hasMessageText ||
        messageData.containsKey('sender_id') ||
        messageData.containsKey('senderId');

    if (!looksLikeMessage) return;

    _messageController.addRealtimeMessage(
      messageData,
      currentUserId: _currentUserId,
    );
    _messageController.markAsReadDebounced();
    _scrollToBottom();
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      AppLogger.d('🎧 SOCKET LISTENER ALREADY ACTIVE');
      return;
    }

    AppLogger.d('🎧 SOCKET LISTENER STARTED');

    _socketSubscription = _socketService.messageStream.listen((data) {
      if (!mounted) return;

      try {
        final type = data['type']?.toString().toLowerCase();

        if (type == 'error') {
          final detail = data['detail']?.toString() ?? 'An error occurred';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Socket Error: $detail'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        _handleIncomingSocketMessage(data);
      } catch (e) {
        AppLogger.d('💥 SOCKET ERROR => $e');
      }
    });
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

  void _showMessagePopup(
    MessageModel message,
    Offset globalPosition,
    Size bubbleSize,
  ) {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    // Calculate safe area height (where the Stack/Scaffold is visible)
    final safeAreaHeight = screenHeight - topInset - keyboardHeight - (keyboardHeight > 0 ? 0.0 : bottomPadding);

    // Height of the popup menu: 5 items (isSent/own message) vs 4 items (received/other message).
    // Each item is 52px, container vertical padding is 4px.
    final double menuHeight = message.isSent ? 264.0 : 212.0;

    // Position of the bubble top/bottom relative to the safe area
    final bubbleTop = globalPosition.dy - topInset;
    final bubbleBottom = bubbleTop + bubbleSize.height;

    double menuTop = bubbleBottom + 10.0;

    // If showing below the bubble exceeds the safe area, show above it.
    if (menuTop + menuHeight > safeAreaHeight - 10.0) {
      final menuTopAbove = bubbleTop - menuHeight - 10.0;
      // Ensure we don't go above the header (height 60)
      if (menuTopAbove >= 60.0) {
        menuTop = menuTopAbove;
      } else {
        // If it doesn't fit above either, clamp it or show it where it fits best.
        // We must ensure min <= max for the clamp method to avoid throwing an error.
        final maxTop = (safeAreaHeight - menuHeight - 10.0).clamp(60.0, double.infinity);
        menuTop = menuTopAbove.clamp(60.0, maxTop);
      }
    }

    setState(() {
      _showPopup = true;
      _popupMessage = message;
      _popupMenuTop = menuTop;
    });
  }

  void _dismissPopup() {
    if (!mounted) return;
    setState(() {
      _showPopup = false;
      _popupMessage = null;
    });
  }

  void _enterDeleteMode() {
    if (!mounted) return;
    setState(() {
      _showPopup = false;
      _isDeleteMode = true;
      _selectedMessageIds.clear();
      final fromPopup = _popupMessage;
      if (fromPopup != null) {
        _selectedMessageIds.add(fromPopup.id);
      }
      _popupMessage = null;
    });
  }

  void _exitDeleteMode() {
    if (!mounted) return;
    setState(() {
      _isDeleteMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _toggleMessageSelection(String messageId) {
    if (!mounted) return;
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _deleteSelectedMessages() {
    if (!mounted) return;
    _messageController.removeMessages(_selectedMessageIds);
    setState(() {
      _isDeleteMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _sendMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    if (_editingMessage != null) {
      unawaited(_submitEdit(trimmedText));
      return;
    }

    final replyMessage = _activeReply?.originalMessage;
    final replyToMessageId = replyMessage?.id;

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final newMessage = MessageModel(
      id: localId,
      text: trimmedText,
      timestamp: DateTime.now(),
      isSent: true,
      senderId: _currentUserId ?? 'me',
      replyTo: replyMessage,
      replyPreview: replyMessage != null
          ? MessageReplyPreview.fromMessage(
              replyMessage,
              senderName: replyMessage.isSent ? 'You' : _userName,
            )
          : null,
      status: MessageStatus.sent,
    );

    if (!mounted) return;
    if (_activeReply != null) {
      setState(() => _activeReply = null);
    }

    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    unawaited(
      _deliverMessage(
        localId: localId,
        content: trimmedText,
        replyToMessageId: replyToMessageId,
      ),
    );
  }

  Future<void> _submitEdit(String trimmedText) async {
    final editing = _editingMessage;
    if (editing == null) return;

    if (trimmedText == editing.text.trim()) {
      _clearEdit();
      return;
    }

    _clearEdit();

    try {
      final socketService = SocketService();
      if (socketService.isConnected) {
        final sent = socketService.sendEvent({
          'type': 'chat.edit',
          'conversation_id': _conversationId,
          'message_id': editing.id,
          'content': trimmedText,
        });
        if (sent) {
          _messageController.handleMessageEdited({
            'message_id': editing.id,
            'content': {'type': 'text', 'text': trimmedText},
            'is_edited': true,
          });
          return;
        }
      }

      final success = await _messageController.editMessage(
        messageId: editing.id,
        content: trimmedText,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to edit message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to edit message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startEdit(MessageModel message) {
    if (!message.isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This message cannot be edited')),
      );
      return;
    }

    setState(() {
      _activeReply = null;
      _editingMessage = message;
      _inputController.text = message.text;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    });
  }

  void _clearEdit() {
    if (_editingMessage == null) return;
    setState(() {
      _editingMessage = null;
      _inputController.clear();
    });
  }

  Future<void> _deliverMessage({
    required String localId,
    String? content,
    String? replyToMessageId,
    MessageMediaPayload? media,
  }) async {
    try {
      await _sendToBackend(
        localId: localId,
        content: content,
        replyToMessageId: replyToMessageId,
        media: media,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Send timeout after 30s'),
      );
    } catch (e) {
      _messageController.markMessageAsFailed(localId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && _isUploadingMedia) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _sendToBackend({
    required String localId,
    String? content,
    String? replyToMessageId,
    MessageMediaPayload? media,
  }) async {
    final mediaPayload = media?.toApiPayload();

    // Prefer REST (POST .../messages/); fall back to WebSocket if REST fails.
    try {
      final restMessage = await _messageController.sendMessage(
        content,
        replyToMessageId: replyToMessageId,
        media: mediaPayload,
        localId: localId,
      );
      if (restMessage != null) return;

      if (await _waitForLocalMessageConfirmation(localId)) return;
    } catch (e) {
      AppLogger.d('[ChatScreen] REST send failed, trying WebSocket: $e');
    }

    final wsSuccess = await _tryWebSocketSend(
      content: content,
      replyToMessageId: replyToMessageId,
      media: mediaPayload,
    ).timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );

    if (wsSuccess) {
      if (await _waitForLocalMessageConfirmation(localId)) return;
      throw Exception('Failed to confirm message via WebSocket');
    }

    throw Exception('Failed to send message');
  }

  Future<bool> _waitForLocalMessageConfirmation(
    String localId, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_messageController.isLocalMessageConfirmed(localId)) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 80));
    }
    return _messageController.isLocalMessageConfirmed(localId);
  }

  Future<bool> _tryWebSocketSend({
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? media,
  }) async {
    try {
      await _messageController.ensureConversationReady();

      if (!_socketService.isConnected) {
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          return false;
        }

        await _socketService.connect(accessToken);
        final connected = await _waitForSocketConnection(_socketService);
        if (!connected) return false;
      }

      _currentUserId ??= await TokenStorage.getCurrentUserId();

      final sanitizedReplyId =
          replyToMessageId != null &&
              !replyToMessageId.startsWith('local-') &&
              !replyToMessageId.startsWith('realtime_')
          ? replyToMessageId
          : null;

      return _socketService.sendMessage(
        conversationId: _messageController.conversationId,
        content: content,
        replyToMessageId: sanitizedReplyId,
        media: media,
        senderId: _currentUserId,
      );
    } catch (e) {
      AppLogger.d('[ChatScreen] WebSocket send exception: $e');
      return false;
    }
  }

  Future<bool> _waitForSocketConnection(SocketService socketService) async {
    const maxAttempts = 40;
    const delay = Duration(milliseconds: 250);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (socketService.isConnected) return true;
      await Future.delayed(delay);
    }

    return socketService.isConnected;
  }

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase().split('?').first;
    const hints = ['.mp4', '.mov', '.m4v', '.webm', '.mkv', '.3gp'];
    for (final hint in hints) {
      if (lower.endsWith(hint)) return true;
    }
    return false;
  }

  void _sendImage(String mediaPath) {
    unawaited(_sendMedia(mediaPath));
  }

  void _sendVoice(String audioPath) {
    unawaited(_sendVoiceMessage(audioPath));
  }

  Future<void> _sendVoiceMessage(String audioPath) async {
    if (_isUploadingMedia) return;

    final replyMessage = _activeReply?.originalMessage;
    final replyToMessageId = replyMessage?.id;

    if (!mounted) return;
    setState(() => _isUploadingMedia = true);

    if (_activeReply != null) {
      setState(() => _activeReply = null);
    }

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final newMessage = MessageModel(
      id: localId,
      text: '',
      timestamp: DateTime.now(),
      isSent: true,
      senderId: _currentUserId ?? 'me',
      imagePath: audioPath,
      mediaKind: 'audio',
      replyTo: replyMessage,
      replyPreview: replyMessage != null
          ? MessageReplyPreview.fromMessage(
              replyMessage,
              senderName: replyMessage.isSent ? 'You' : _userName,
            )
          : null,
      status: MessageStatus.sent,
    );

    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    try {
      final uploaded = await _messageController.uploadMessageMedia(audioPath);
      await _deliverMessage(
        localId: localId,
        content: '',
        replyToMessageId: replyToMessageId,
        media: uploaded,
      );
    } catch (e) {
      _messageController.markMessageAsFailed(localId);
      if (mounted) {
        setState(() => _isUploadingMedia = false);
        
        String errorMsg = e.toString();
        if (errorMsg.contains('413')) {
          errorMsg = 'File too large (> 10 MB)';
        } else if (errorMsg.contains('400')) {
          errorMsg = 'Unsupported audio format';
        } else if (errorMsg.contains('403')) {
          errorMsg = 'Not a conversation participant';
        } else {
          errorMsg = 'Failed to upload voice message: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMedia(String mediaPath) async {
    if (_isUploadingMedia) return;

    final isVideo = _isVideoPath(mediaPath);
    final caption = _inputController.text.trim();
    final replyMessage = _activeReply?.originalMessage;
    final replyToMessageId = replyMessage?.id;

    if (!mounted) return;
    setState(() => _isUploadingMedia = true);

    if (_activeReply != null) {
      setState(() => _activeReply = null);
    }
    if (caption.isNotEmpty) {
      _inputController.clear();
    }

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final newMessage = MessageModel(
      id: localId,
      text: caption,
      timestamp: DateTime.now(),
      isSent: true,
      senderId: _currentUserId ?? 'me',
      imagePath: mediaPath,
      mediaKind: isVideo ? 'video' : 'image',
      replyTo: replyMessage,
      replyPreview: replyMessage != null
          ? MessageReplyPreview.fromMessage(
              replyMessage,
              senderName: replyMessage.isSent ? 'You' : _userName,
            )
          : null,
      status: MessageStatus.sent,
    );

    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    try {
      final uploaded = await _messageController.uploadMessageMedia(mediaPath);
      await _deliverMessage(
        localId: localId,
        content: caption.isEmpty ? null : caption,
        replyToMessageId: replyToMessageId,
        media: uploaded,
      );
    } catch (e) {
      _messageController.markMessageAsFailed(localId);
      if (mounted) {
        setState(() => _isUploadingMedia = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    AppLogger.d('[ChatScreen] 🎯 Message action=$action id=${message.id}');
    _dismissPopup();

    switch (action) {
      case MessageAction.reply:
        if (!mounted) return;
        setState(() {
          _activeReply = ReplyMessageModel(
            originalMessage: message,
            username: message.isSent ? 'yourself' : _userName,
            previewText: MessageReplyPreview.fromMessage(
              message,
              senderName: message.isSent ? 'You' : _userName,
            ).displayText,
          );
        });
        break;
      case MessageAction.edit:
        _startEdit(message);
        break;
      case MessageAction.pin:
        _pinMessage(message);
        break;
      case MessageAction.report:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report feature coming soon!')),
        );
        break;
      case MessageAction.delete:
        // Check if it's user's own message
        if (message.isSent) {
          AppLogger.d(
            '[ChatScreen] 🗑️ 👤 Own message - showing delete confirmation',
          );
          _showDeleteConfirmation(message);
        } else {
          AppLogger.d('[ChatScreen] ⚠️ 🚫 Not own message - cannot delete');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only delete your own messages'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
    }
  }

  void _pinMessage(MessageModel message) {
    if (_pinnedMessage != null) {
      _messageController.replaceMessage(
        _pinnedMessage!.copyWith(isPinned: false),
      );
    }

    final pinned = message.copyWith(isPinned: true);
    _messageController.replaceMessage(pinned);
    if (!mounted) return;
    setState(() => _pinnedMessage = pinned);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$_userName pinned a message')));
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(MessageModel message) async {
    AppLogger.d(
      '🗑️ [ChatScreen] 💬 Showing delete confirmation for message: ${message.id}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Message?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This message will be deleted for you. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.d('🗑️ [ChatScreen] ❌ Delete cancelled by user');
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              AppLogger.d('🗑️ [ChatScreen] ✅ Delete confirmed by user');
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF51829).withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFF51829),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppLogger.d('🗑️ [ChatScreen] 🚀 User confirmed - proceeding with delete');
      await _deleteSingleMessage(message);
    } else {
      AppLogger.d(
        '🗑️ [ChatScreen] ⚠️ Delete not confirmed or context unmounted',
      );
    }
  }

  /// Delete a single message
  Future<void> _deleteSingleMessage(MessageModel message) async {
    AppLogger.d(
      '🗑️ [ChatScreen] 🚀 Starting delete process for message: ${message.id}',
    );
    AppLogger.d(
      '💬 [ChatScreen] 📝 Message text: ${message.text.substring(0, message.text.length.clamp(0, 50))}${message.text.length > 50 ? "..." : ""}',
    );

    try {
      AppLogger.d(
        '📡 [ChatScreen] 🌐 Calling MessageController.deleteMessage...',
      );
      final success = await _messageController.deleteMessage(message.id);

      if (!mounted) {
        AppLogger.d('⚠️ [ChatScreen] ❌ Context unmounted after delete');
        return;
      }

      if (success) {
        AppLogger.d('✅ [ChatScreen] 🎉 Message deleted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        AppLogger.d('❌ [ChatScreen] ⚠️ Delete failed - showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.d('💥 [ChatScreen] ❌ Error deleting message: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearReply() {
    if (!mounted) return;
    setState(() => _activeReply = null);
  }

  Widget _buildEditPreviewBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Editing message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearEdit,
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser() async {
    final blockProvider = context.read<BlockProvider>();
    final isBlocked = blockProvider.isBlocked(_userId);

    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'UnblockUserDialog',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BlockUserWidget(
          name: _userName,
          username: "@$_userName",
          userId: _userId,
          isBlocked: isBlocked,
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.removeListener(_onMessageControllerTick);
    _scrollController.removeListener(_onMessageScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    AppLogger.d('[ChatScreen] dispose conversation=$_conversationId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleteMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isDeleteMode) {
          _exitDeleteMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.95, 0.31),
              end: Alignment(0.95, -0.31),
              colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    ChatHeader(
                      userOrConversation: widget.userOrConversation,
                      explicitUserName: _userName,
                      explicitUserId: _userId,
                      explicitProfileImage: _userAvatar,
                      onBack: () async {
                        if (_isDeleteMode) {
                          _exitDeleteMode();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _messageController,
                        builder: (context, _) =>
                            _buildMessageBody(_messageController.messagesNewestFirst),
                      ),
                    ),
                    Selector<BlockProvider, bool>(
                      selector: (_, block) => block.isBlocked(_userId),
                      builder: (context, isBlocked, _) {
                        return ListenableBuilder(
                          listenable: _messageController,
                          builder: (context, _) {
                            if (_messageController.isInitialLoading) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_activeReply != null && !_isDeleteMode)
                                  ReplyPreviewBar(
                                    replyMessage: _activeReply!,
                                    onClose: _clearReply,
                                  ),
                                if (_editingMessage != null && !_isDeleteMode)
                                  _buildEditPreviewBar(),
                                if (_isDeleteMode)
                                  _buildDeleteBottomBar()
                                else if (isBlocked)
                                  _buildBlockedBottomBar()
                                else
                                  ChatInputField(
                                    controller: _inputController,
                                    hintText: _editingMessage != null
                                        ? 'Edit message'
                                        : null,
                                    onSendMessage: _sendMessage,
                                    onSendImage: _sendImage,
                                    onSendVoice: _sendVoice,
                                    isLoading: _isUploadingMedia,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                if (_showPopup)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _dismissPopup,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Menu only (no duplicate bubble — avoids tight-height relayout crashes).
                if (_showPopup && _popupMessage != null)
                  Positioned(
                    top: _popupMenuTop + 4,
                    left: 16,
                    child: MessagePopupMenu(
                      selectedAction: null,
                      onActionSelected: (action) =>
                          _handleMessageAction(action, _popupMessage!),
                      onDeleteMode: _enterDeleteMode,
                      onDismiss: _dismissPopup,
                      isOwnMessage: _popupMessage!.isSent,
                      canEdit: _popupMessage!.isEditable,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBody(List<MessageModel> sortedMessages) {
    if (_messageController.isInitialLoading && sortedMessages.isEmpty) {
      return const ChatBubbleShimmer(itemCount: 8);
    }

    if (_messageController.hasError && sortedMessages.isEmpty) {
      return _buildErrorState();
    }

    if (sortedMessages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const BouncingScrollPhysics(),
      reverse: true,
      cacheExtent: 1000,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount:
          sortedMessages.length + (_messageController.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_messageController.isLoadingMore && index == sortedMessages.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final messageIndex = index;
        final message = sortedMessages[messageIndex];
        return _buildMessageRow(message, messageIndex);
      },
    );
  }

  Widget _buildMessageRow(MessageModel message, int index) {
    final isSelected = _selectedMessageIds.contains(message.id);
    final stableKey = message.id.startsWith('local-')
        ? 'local_${message.timestamp.microsecondsSinceEpoch}_${message.text.hashCode}'
        : message.id;

    Widget bubble = MessageBubble(
      message: message,
      onActionSelected: (action) => _handleMessageAction(action, message),
      onLongPress: (globalPos, size) =>
          _showMessagePopup(message, globalPos, size),
    );

    if (_isDeleteMode) {
      bubble = MessageWithCheckbox(
        message: bubble,
        isSelected: isSelected,
        onTap: () => _toggleMessageSelection(message.id),
        onCheckboxChanged: (_) => _toggleMessageSelection(message.id),
      );
    }

    return RepaintBoundary(
      key: ValueKey(stableKey),
      child: Column(
        children: [
          if (index > 0) const SizedBox(height: 10),
          bubble,
          if (message.isPinned)
            PinnedMessageBanner(pinnedMessage: message, username: _userName),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 46),
            const SizedBox(height: 14),
            Text(
              _messageController.error ?? 'Unable to load messages',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 46),
          SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Send a message to start the chat',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'If this chat is reported, recently deleted message will be included in the report',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedMessageIds.isNotEmpty
                  ? _deleteSelectedMessages
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete for you (${_selectedMessageIds.length})',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'You blocked $_userName',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _unblockUser,
            child: const Text(
              'Unblock',
              style: TextStyle(color: Color(0xFFCD72E3)),
            ),
          ),
        ],
      ),
    );
  }
}
