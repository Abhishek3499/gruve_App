import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/message/presentation/widgets/message_emoji_reaction.dart';
import 'package:gruve_app/features/user_profile/presentation/notifiers/block_notifier.dart';

import 'package:gruve_app/core/services/socket_service.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';

import 'package:gruve_app/features/message/presentation/controller/message_controller.dart';
import 'package:gruve_app/features/message/presentation/notifiers/message_notifier.dart';
import 'package:gruve_app/features/message/domain/entities/conversation_model.dart';
import 'package:gruve_app/features/message/domain/entities/message_media_model.dart';
import 'package:gruve_app/features/message/domain/entities/message_reply_preview.dart';
import 'package:gruve_app/features/message/domain/entities/message_model.dart';
import 'package:gruve_app/features/message/domain/entities/reply_message_model.dart';
import 'package:gruve_app/features/message/data/datasource/message_service.dart';
import 'package:gruve_app/features/message/presentation/widgets/chat_header.dart';
import 'package:gruve_app/features/message/presentation/widgets/chat_header_menu.dart';
import 'package:gruve_app/features/message/presentation/widgets/chat_input_field.dart';
import 'package:gruve_app/features/message/presentation/widgets/message_bubble.dart';
import 'package:gruve_app/features/message/presentation/widgets/message_popup_menu.dart';
import 'package:gruve_app/features/message/presentation/widgets/block/block_user_widget.dart';
import 'package:gruve_app/features/message/presentation/widgets/pinned_message_banner.dart';
import 'package:gruve_app/features/message/presentation/widgets/reply_preview_bar.dart';
import 'package:gruve_app/features/message/presentation/widgets/shimmer/chat_shimmer.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/services/media_upload_service.dart';
import 'package:gruve_app/shared/widgets/optimized/optimized_image.dart';

class ChatScreen extends ConsumerStatefulWidget {
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
         conversationId != null ||
             receiverId != null ||
             userOrConversation != null,
         'Either conversationId, receiverId, or userOrConversation must be provided',
       );

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final MessageController _messageController;
  late final ValueNotifier<bool> _isInitialLoadingNotifier;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();
  final TextEditingController _inputController = TextEditingController();
  final SocketService _socketService = SocketService();
  final MediaUploadService _mediaUploadService = MediaUploadService();

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

  bool _showHeaderMenu = false;

  bool _isDeleteMode = false;
  final Set<String> _selectedMessageIds = {};

  // Typing indicator
  bool _otherUserTyping = false;
  Timer? _otherTypingTimer;   // auto-clear peer typing indicator
  Timer? _selfTypingThrottle; // throttle outgoing typing.start
  bool _isSelfTyping = false;

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

  // emoji picker modal bottom sheet

  void _onTypingChanged(String value) {
    if (value.trim().isEmpty) {
      // Field cleared — just reset flag, server handles stop automatically
      _selfTypingThrottle?.cancel();
      _isSelfTyping = false;
      return;
    }
    // Throttle: send typing.start at most once every 1.5s
    if (_isSelfTyping) return;
    _isSelfTyping = true;
    _socketService.sendTyping(conversationId: _conversationId, isTyping: true);
    AppLogger.d('[ChatScreen] typing.start sent for $_conversationId');
    _selfTypingThrottle = Timer(const Duration(milliseconds: 1500), () {
      _isSelfTyping = false;
    });
  }

  void _handleTypingEvent(Map<String, dynamic> data, String? event) {
    final incomingConversationId = _extractConversationId(data);
    if (incomingConversationId.isNotEmpty &&
        incomingConversationId != _conversationId) return;

    final senderId = data['user_id']?.toString() ?? '';
    if (senderId == _currentUserId) return;

    // Server sends type="typing", event="typing.start" or event="typing.stop"
    final isStart = event == 'typing.start';

    if (!mounted) return;
    _otherTypingTimer?.cancel();
    setState(() => _otherUserTyping = isStart);

    if (isStart) {
      _scrollToBottom();
      // Fallback: auto-clear after 5s if typing.stop is missed
      _otherTypingTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _otherUserTyping = false);
      });
    }
  }

  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MessageEmojiReaction(
          onEmojiSelected: (emoji) {
            final currentText = _inputController.text;

            _inputController.text = currentText + emoji;

            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputController.text.length),
            );

            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _openReactionEmojiPicker() {
    final message = _popupMessage;

    if (message == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MessageEmojiReaction(
          onEmojiSelected: (emoji) {
            Navigator.pop(context);
            _dismissPopup();

            // Optimistic update
            final optimistic = [
              ...message.reactions.where((r) => r.userId != (_currentUserId ?? '')),
              MessageReaction(userId: _currentUserId ?? '', emoji: emoji),
            ];
            _messageController.replaceMessage(
              message.copyWith(reactions: optimistic),
            );

            _socketService.sendMessageReaction(
              conversationId: _conversationId,
              messageId: message.id,
              emoji: emoji,
            );
          },
        );
      },
    );
  }

  void _handleReactionSelected(String emoji) {
    final message = _popupMessage;
    if (message == null) return;

    // Optimistic update: replace current user's reaction
    final optimistic = [
      ...message.reactions.where((r) => r.userId != (_currentUserId ?? '')),
      MessageReaction(userId: _currentUserId ?? '', emoji: emoji),
    ];
    _messageController.replaceMessage(message.copyWith(reactions: optimistic));
    _dismissPopup();

    _socketService.sendMessageReaction(
      conversationId: _conversationId,
      messageId: message.id,
      emoji: emoji,
    );
  }

  void _handleReactionRemoved(MessageModel message, String emoji) {
    // Optimistic update: remove this user's reaction
    final optimistic = message.reactions
        .where((r) => !(r.userId == (_currentUserId ?? '') && r.emoji == emoji))
        .toList();
    _messageController.replaceMessage(message.copyWith(reactions: optimistic));

    _socketService.sendMessageReaction(
      conversationId: _conversationId,
      messageId: message.id,
      emoji: emoji,
    );
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
    _isInitialLoadingNotifier = ValueNotifier(
      _messageController.isInitialLoading,
    );
    _messageController.addListener(_syncInitialLoadingNotifier);
    _scrollController.addListener(_onMessageScroll);
    _mediaUploadService.addListener(_onUploadChanged);
    _initializeSocketListener();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _currentUserId = await TokenStorage.getCurrentUserId();
      if (!mounted) return;
      final blockNotifier = ref.read(blockNotifierProvider.notifier);
      try {
        await blockNotifier.fetchBlockedUsers();
        if (!mounted) return;
        final isBlocked = blockNotifier.blockedUsers.any(
          (user) => user.userId == _userId,
        );
        blockNotifier.setBlockState(_userId, isBlocked);
        AppLogger.d(
          '[ChatScreen] Block state synced from backend = $isBlocked',
        );
      } catch (e) {
        AppLogger.d('[ChatScreen] Failed to sync block state: $e');
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

  void _onUploadChanged() {
    if (mounted) setState(() {});
  }

  void _onMessageScroll() {
    if (!_scrollController.hasClients || _messageController.isInitialLoading) {
      return;
    }

    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: _isLoadingOlderMessages || _messageController.isLoadingMore,
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

  /// Mirrors [MessageController.isInitialLoading] into a [ValueNotifier] so the
  /// input-area subtree only rebuilds when this specific flag changes, instead
  /// of on every unrelated controller notification.
  void _syncInitialLoadingNotifier() {
    if (!mounted) return;
    _isInitialLoadingNotifier.value = _messageController.isInitialLoading;
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

    // Optimistically update conversation details in MessageNotifier for instant refresh on back navigation
    if (!_messageController.isInitialLoading &&
        !_messageController.hasError &&
        _messageController.hasMessages) {
      final conversationId = _messageController.conversationId;
      if (conversationId.isNotEmpty) {
        final lastMsg = _messageController.messagesNewestFirst.first;
        final messageNotifier = ref.read(messageNotifierProvider.notifier);
        final existingConversation = messageNotifier.getConversationById(
          conversationId,
        );

        if (existingConversation != null) {
          final updated = existingConversation.copyWith(
            lastMessage: LastMessage(
              content: lastMsg.text.isEmpty && lastMsg.hasMedia
                  ? (lastMsg.mediaKind == 'audio'
                        ? 'Voice message'
                        : lastMsg.mediaKind ?? 'Media')
                  : lastMsg.text,
              createdAt: lastMsg.timestamp,
              messageKind: lastMsg.mediaKind,
            ),
            hasLastMessage: true,
            updatedAt: lastMsg.timestamp,
            unreadCount: 0,
          );
          messageNotifier.updateConversation(updated);
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
                  ? (lastMsg.mediaKind == 'audio'
                        ? 'Voice message'
                        : lastMsg.mediaKind ?? 'Media')
                  : lastMsg.text,
              createdAt: lastMsg.timestamp,
              messageKind: lastMsg.mediaKind,
            ),
            hasLastMessage: true,
            updatedAt: lastMsg.timestamp,
            unreadCount: 0,
          );
          messageNotifier.updateConversation(newConversation);
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

  void _scrollToMessage(String messageId) {
    if (messageId.isEmpty) return;

    void ensureTargetVisible() {
      if (!mounted) return;
      final targetContext = _messageKeys[messageId]?.currentContext;
      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    }

    if (_messageKeys[messageId]?.currentContext != null) {
      ensureTargetVisible();
      return;
    }

    final targetIndex = _messageController.messagesNewestFirst.indexWhere(
      (message) => message.id == messageId,
    );
    if (targetIndex < 0 || !_scrollController.hasClients) return;

    final estimatedOffset = (targetIndex * 110.0)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _scrollController
        .animateTo(
          estimatedOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ensureTargetVisible();
          });
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

    // Server sends type="typing" with event="typing.start" or "typing.stop"
    if (type == 'typing') {
      _handleTypingEvent(data, event);
      return;
    }

    if (!_isChatSocketEvent(type, event)) return;

    if (event == 'message.reaction') {
      _handleMessageReactionEvent(data);
      return;
    }

    if (_isDeliveryEvent(type, event)) {
      final messageData = _extractMessagePayload(data);
      final messageId =
          messageData['message_id']?.toString() ??
          messageData['id']?.toString();
      if (messageId != null && messageId.isNotEmpty) {
        final content =
            messageData['content']?.toString() ??
            messageData['text']?.toString();
        _messageController.handleMessageDelivered(messageId, content: content);
      }
      return;
    }

    if (_isReadEvent(type, event)) {
      final messageData = _extractMessagePayload(data);
      final messageIds = (messageData['message_ids'] as List?)
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

  void _handleMessageReactionEvent(Map<String, dynamic> data) {
    final incomingConversationId = _extractConversationId(data);

    if (incomingConversationId.isNotEmpty &&
        incomingConversationId != _conversationId) {
      return;
    }

    final rawData = data['data'];

    if (rawData is! Map) {
      AppLogger.d(
        '[ChatScreen] Invalid message.reaction payload: missing data',
      );
      return;
    }

    _messageController.handleMessageReaction(
      Map<String, dynamic>.from(rawData),
    );
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      AppLogger.d('[ChatScreen] Socket listener already active');
      return;
    }

    AppLogger.d('[ChatScreen] Socket listener initialized');

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
        AppLogger.d('[ChatScreen] Socket listener error: $e');
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
    final safeAreaHeight =
        screenHeight -
        topInset -
        keyboardHeight -
        (keyboardHeight > 0 ? 0.0 : bottomPadding);

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
        final maxTop = (safeAreaHeight - menuHeight - 10.0).clamp(
          60.0,
          double.infinity,
        );
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

  void _openHeaderMenu() {
    if (!mounted) return;
    setState(() => _showHeaderMenu = true);
  }

  void _closeHeaderMenu() {
    if (!mounted) return;
    setState(() => _showHeaderMenu = false);
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

    // Reset typing throttle on send (server auto-stops the peer's indicator)
    _selfTypingThrottle?.cancel();
    _isSelfTyping = false;

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
    ).timeout(const Duration(seconds: 8), onTimeout: () => false);

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
    if (_activeReply != null) setState(() => _activeReply = null);

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
    if (mounted) setState(() => _isUploadingMedia = false);

    await _mediaUploadService.enqueue(
      localId: localId,
      conversationId: _conversationId,
      filePath: audioPath,
      mediaKind: 'audio',
      replyToMessageId: replyToMessageId,
      onSuccess: (sent) {
        if (mounted) _messageController.replaceMessage(sent);
      },
      onFailure: (id) {
        if (mounted) _messageController.markMessageAsFailed(id);
      },
    );
  }

  Future<void> _sendMedia(String mediaPath) async {
    if (_isUploadingMedia) return;

    final isVideo = _isVideoPath(mediaPath);
    final caption = _inputController.text.trim();
    final replyMessage = _activeReply?.originalMessage;
    final replyToMessageId = replyMessage?.id;

    if (!mounted) return;
    setState(() => _isUploadingMedia = true);
    if (_activeReply != null) setState(() => _activeReply = null);
    if (caption.isNotEmpty) _inputController.clear();

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
    if (mounted) setState(() => _isUploadingMedia = false);

    await _mediaUploadService.enqueue(
      localId: localId,
      conversationId: _conversationId,
      filePath: mediaPath,
      mediaKind: isVideo ? 'video' : 'image',
      caption: caption.isEmpty ? null : caption,
      replyToMessageId: replyToMessageId,
      onSuccess: (sent) {
        if (mounted) _messageController.replaceMessage(sent);
      },
      onFailure: (id) {
        if (mounted) _messageController.markMessageAsFailed(id);
      },
    );
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    AppLogger.d('[ChatScreen] Message action=$action id=${message.id}');
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
          AppLogger.d('[ChatScreen] Own message - showing delete confirmation');
          _showDeleteConfirmation(message);
        } else {
          AppLogger.d('[ChatScreen] Not own message - cannot delete');
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
      '[ChatScreen] Showing delete confirmation for message: ${message.id}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.chatBackground,
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
              AppLogger.d('[ChatScreen] Delete cancelled by user');
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              AppLogger.d('[ChatScreen] Delete confirmed by user');
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
      AppLogger.d('[ChatScreen] User confirmed - proceeding with delete');
      await _deleteSingleMessage(message);
    } else {
      AppLogger.d('[ChatScreen] Delete not confirmed or context unmounted');
    }
  }

  /// Delete a single message
  Future<void> _deleteSingleMessage(MessageModel message) async {
    AppLogger.d(
      '[ChatScreen] Starting delete process for message: ${message.id}',
    );

    try {
      final success = await _messageController.deleteMessage(message.id);

      if (!mounted) {
        AppLogger.d('[ChatScreen] Context unmounted after delete');
        return;
      }

      if (success) {
        AppLogger.d('[ChatScreen] Message deleted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        AppLogger.d('[ChatScreen] Delete failed - showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.d('[ChatScreen] Error deleting message: $e');

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
    final blockNotifier = ref.read(blockNotifierProvider.notifier);
    final isBlocked = blockNotifier.isBlocked(_userId);

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
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _selfTypingThrottle?.cancel();
    _otherTypingTimer?.cancel();
    _isSelfTyping = false;
    _messageController.removeListener(_onMessageControllerTick);
    _messageController.removeListener(_syncInitialLoadingNotifier);
    _scrollController.removeListener(_onMessageScroll);
    _mediaUploadService.removeListener(_onUploadChanged);
    _messageController.dispose();
    _isInitialLoadingNotifier.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    AppLogger.d('[ChatScreen] dispose conversation=$_conversationId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleteMode && !_showHeaderMenu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showHeaderMenu) {
          _closeHeaderMenu();
        } else if (_isDeleteMode) {
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
              colors: [
                AppColors.deepPlum,
                Color(0xFF210C26),
                Color(0xFF000000),
              ],
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
                      isTyping: false,
                      onBack: () async {
                        if (_showHeaderMenu) {
                          _closeHeaderMenu();
                        } else if (_isDeleteMode) {
                          _exitDeleteMode();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      onMenuTap: _openHeaderMenu,
                    ),
                    // Background upload progress banner
                    ..._mediaUploadService
                        .uploadsFor(_conversationId)
                        .where(
                          (u) =>
                              u.status == UploadStatus.uploading ||
                              u.status == UploadStatus.sending,
                        )
                        .map(
                          (u) => _UploadProgressBanner(
                            mediaKind: u.mediaKind,
                            status: u.status,
                          ),
                        ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _messageController,
                        builder: (context, _) => _buildMessageBody(
                          _messageController.messagesNewestFirst,
                          isTyping: _otherUserTyping,
                        ),
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isBlocked = ref.watch(
                          blockNotifierProvider.select(
                            (state) => state.isBlocked(_userId),
                          ),
                        );
                        return ValueListenableBuilder<bool>(
                          valueListenable: _isInitialLoadingNotifier,
                          builder: (context, isInitialLoading, _) {
                            if (isInitialLoading) {
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
                                    onEmojiPressed: _openEmojiPicker,
                                    onChanged: _onTypingChanged,
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
                      onReactionSelected: _handleReactionSelected,
                      onDeleteMode: _enterDeleteMode,
                      onDismiss: _dismissPopup,
                      isOwnMessage: _popupMessage!.isSent,
                      canEdit: _popupMessage!.isEditable,
                      onMoreReactions: _openReactionEmojiPicker,
                    ),
                  ),
                if (_showHeaderMenu)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeHeaderMenu,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                if (_showHeaderMenu)
                  Positioned(
                    top: 60,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {},
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isBlocked = ref
                              .read(blockNotifierProvider.notifier)
                              .isBlocked(_userId);
                          return ChatHeaderMenu(
                            onClose: _closeHeaderMenu,
                            chatNavigator: Navigator.of(context),
                            userId: _userId,
                            userName: _userName,
                            isBlocked: isBlocked,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBody(List<MessageModel> sortedMessages, {bool isTyping = false}) {
    if (_messageController.isInitialLoading && sortedMessages.isEmpty) {
      return const ChatBubbleShimmer(itemCount: 8);
    }

    if (_messageController.hasError && sortedMessages.isEmpty) {
      return _buildErrorState();
    }

    if (sortedMessages.isEmpty && !isTyping) {
      return _buildEmptyState();
    }

    // +1 for typing bubble when active
    final typingSlot = isTyping ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const BouncingScrollPhysics(),
      reverse: true,
      cacheExtent: 1000,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount: sortedMessages.length +
          (_messageController.isLoadingMore ? 1 : 0) +
          typingSlot,
      itemBuilder: (context, index) {
        // index 0 (bottom of reversed list) = typing bubble
        if (isTyping && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4, top: 4),
            child: _TypingBubble(
              avatarUrl: _userAvatar,
              name: _userName,
            ),
          );
        }

        final adjustedIndex = index - typingSlot;

        if (_messageController.isLoadingMore &&
            adjustedIndex == sortedMessages.length) {
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

        final message = sortedMessages[adjustedIndex];
        return _buildMessageRow(message, adjustedIndex);
      },
    );
  }

  Widget _buildMessageRow(MessageModel message, int index) {
    final isSelected = _selectedMessageIds.contains(message.id);

    Widget bubble = MessageBubble(
      message: message,
      onReactionTap: (emoji) => _handleReactionRemoved(message, emoji),
      onReplyTap: () {
        final replyPreview = message.effectiveReplyPreview;
        if (replyPreview != null) {
          _scrollToMessage(replyPreview.messageId);
        }
      },
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
      key: _messageKeys.putIfAbsent(message.id, GlobalKey.new),
      child: Column(
        children: [
          if (index > 0) const SizedBox(height: 18),
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
              style: TextStyle(color: AppColors.softPurple),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin banner shown below the header while a media upload runs in background.
class _UploadProgressBanner extends StatelessWidget {
  final String mediaKind;
  final UploadStatus status;

  const _UploadProgressBanner({
    required this.mediaKind,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final label = status == UploadStatus.sending
        ? 'Sending ${mediaKind}…'
        : 'Uploading ${mediaKind}…';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white.withValues(alpha: 0.08),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three-dot animated typing bubble shown in the message list.
class _TypingBubble extends StatefulWidget {
  final String? avatarUrl;
  final String name;

  const _TypingBubble({required this.avatarUrl, required this.name});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OptimizedAvatar(
          imageUrl: widget.avatarUrl,
          name: widget.name,
          radius: 14,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${widget.name} is typing',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final offset = ((_controller.value * 3) - i) % 3.0;
                    final scale = offset < 1.0
                        ? 0.6 + 0.4 * offset
                        : offset < 2.0
                            ? 1.0 - 0.4 * (offset - 1.0)
                            : 0.6;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 5 * scale,
                      height: 5 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
