import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:provider/provider.dart';

import '../../../services/socket_service.dart';
import '../../../features/auth/token_storage.dart';

import '../controllers/message_controller.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/reply_message_model.dart';
import '../services/message_service.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_popup_menu.dart';
import '../widgets/pinned_message_banner.dart';
import '../widgets/reply_preview_bar.dart';
import '../../../core/widgets/shimmer/chat_shimmer.dart';
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
  final SocketService _socketService = SocketService();

  StreamSubscription? _socketSubscription;

  bool _isSending = false;
  bool _isLoadingOlderMessages = false;
  bool _hasCompletedInitialScroll = false;
  String? _resolvedConversationId;
  ReplyMessageModel? _activeReply;
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
    if (_useExplicitData && widget.profileImage != null) {
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

  List<MessageModel> get _messages => _messageController.messages;
  bool _isBlocked(BuildContext context) {
    return context.watch<BlockProvider>().isBlocked(_userId);
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
        _isLoadingOlderMessages ||
        _messageController.isLoadingMore ||
        !_messageController.hasMoreData ||
        _messageController.isInitialLoading) {
      return;
    }

    // With reverse: true, scrolling UP increases pixels towards maxScrollExtent.
    // Fetch older messages when we are within 200 pixels of the top (maxScrollExtent).
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (!_scrollController.hasClients) return;

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
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0, // With reverse: true, 0.0 is the bottom
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      AppLogger.d('🎧 SOCKET LISTENER ALREADY ACTIVE');
      return;
    }

    AppLogger.d('🎧 SOCKET LISTENER STARTED');

    _socketSubscription = _socketService.messageStream.listen((data) {
      AppLogger.d('🔥 SOCKET DATA => $data');

      try {
        final event = data['event']?.toString();
        final type = data['type']?.toString().toLowerCase();

        if (type == 'error') {
          final detail = data['detail']?.toString() ?? 'An error occurred';
          AppLogger.d('💥 SOCKET ERROR EVENT => $detail');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Socket Error: $detail'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        if (type == 'message') {
          if (event == 'message.delivered') {
            final nested = data['data'];
            if (nested is Map) {
              final messageId = nested['message_id']?.toString();
              if (messageId != null) {
                _messageController.handleMessageDelivered(messageId);
              }
            }
            return;
          } else if (event == 'message.read') {
            final nested = data['data'];
            if (nested is Map) {
              final messageIds = (nested['message_ids'] as List?)?.map((e) => e.toString()).toList();
              _messageController.handleMessagesRead(messageIds);
            }
            return;
          }

          // Default / Fallback case: new message event (event == 'message.sent' or general message)
          final nested = data['data'];
          final messageData = nested is Map
              ? Map<String, dynamic>.from(nested)
              : Map<String, dynamic>.from(data);

          final incomingConversationId = _extractConversationId(data);

          // Adopt conversation ID if empty and message is relevant to this user
          if (incomingConversationId.isNotEmpty && _conversationId.isEmpty) {
            final senderIdStr = (messageData['sender_id'] ?? messageData['senderId'] ?? '').toString();
            final receiverIdStr = (messageData['receiver_id'] ?? messageData['receiverId'] ?? '').toString();
            final isRelevant = senderIdStr == _userId || receiverIdStr == _userId;

            if (isRelevant) {
              AppLogger.d('[ChatScreen] Adopting new conversation ID from socket: $incomingConversationId');
              _resolvedConversationId = incomingConversationId;
              _messageController.conversationId = incomingConversationId;
              _messageController.onConversationIdChanged?.call(incomingConversationId);
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

          if (looksLikeMessage) {
            _messageController.addRealtimeMessage(messageData);
            _messageController.markAsReadDebounced();
            AppLogger.d('✅ REALTIME MESSAGE ADDED');
            _scrollToBottom();
          }
        }
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
    final topInset = MediaQuery.of(context).padding.top;
    final menuTop = (globalPosition.dy - topInset) + bubbleSize.height + 10;
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

  void _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    AppLogger.d(
      '[ChatScreen] 📤 SEND FLOW START: conversation=$_conversationId',
    );
    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final newMessage = MessageModel(
      id: localId,
      text: trimmedText,
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
      replyTo: _activeReply?.originalMessage,
      status: MessageStatus.sent,
    );

    if (!mounted) return;
    setState(() {
      _isSending = true;
      _activeReply = null;
    });

    // Step 1: Optimistic local append
    AppLogger.d('[ChatScreen] 📝 Step 1: Local message appended id=$localId');
    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    // Step 2: Attempt backend persistence with timeout protection
    try {
      AppLogger.d('[ChatScreen] 🌐 Step 2: Starting backend send...');

      await _sendToBackend(trimmedText).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Send timeout after 15s'),
      );

      AppLogger.d('[ChatScreen] ✅ Step 3: Backend send SUCCESS');
      // The socket listener handles adding and replacing the optimistic message
      _scrollToBottom();
    } catch (e) {
      AppLogger.d('[ChatScreen] ❌ Step 3: Backend send FAILED: $e');
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
      if (mounted) {
        setState(() => _isSending = false);
      }
      AppLogger.d('[ChatScreen] 🏁 SEND FLOW COMPLETE');
    }
  }

  Future<void> _sendToBackend(String content) async {
    AppLogger.d('[ChatScreen] 🔄 Backend send: WebSocket is primary, REST is fallback ONLY');

    final socketService = SocketService();
    if (socketService.isConnected) {
      AppLogger.d('[ChatScreen] Socket is connected. Using WebSocket only.');
      final wsSuccess = await _tryWebSocketSend(content).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          AppLogger.d('[ChatScreen] WebSocket send timed out after 12s');
          return false;
        },
      );

      if (wsSuccess) {
        AppLogger.d('[ChatScreen] ✅ WebSocket send SUCCESS');
        return;
      }
      throw Exception('Failed to send message via WebSocket');
    } else {
      AppLogger.d('[ChatScreen] Socket is NOT connected. Using REST fallback.');
      final restMessage = await _messageController.sendMessage(content);
      if (restMessage != null) {
        AppLogger.d('[ChatScreen] ✅ REST fallback send SUCCESS');
        return;
      }
      throw Exception('Failed to send message via REST fallback');
    }
  }

  Future<bool> _tryWebSocketSend(String content) async {
    try {
      AppLogger.d('[ChatScreen] 📡 WebSocket send attempt start');
      final socketService = SocketService();

      if (!socketService.isConnected) {
        AppLogger.d('[ChatScreen] ⚠️ WebSocket NOT CONNECTED');
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          AppLogger.d('[ChatScreen] No token available for WebSocket reconnect');
          return false;
        }

        await socketService.connect(accessToken);
        final connected = await _waitForSocketConnection(socketService);
        if (!connected) {
          AppLogger.d('[ChatScreen] WebSocket reconnect did not complete');
          return false;
        }
      }

      final sent = socketService.sendMessage(
        conversationId: _conversationId,
        message: content,
      );

      AppLogger.d('[ChatScreen] 📡 WebSocket send result: $sent');
      return sent;
    } catch (e) {
      AppLogger.d('[ChatScreen] ❌ WebSocket send exception: $e');
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

  void _sendImage(String imagePath) {
    AppLogger.d('[ChatScreen] 🖼️ Image send not yet implemented: $imagePath');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image sending coming soon!')));
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
            previewText: message.text.isNotEmpty ? message.text : 'Image',
          );
        });
        break;
      case MessageAction.forward:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forward feature coming soon!')),
        );
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

  Future<void> _unblockUser() async {
    final blockProvider = context.read<BlockProvider>();
    await blockProvider.toggleBlockUser(
      _userId,
      refreshList: true,
      optimistic: false,
    );
  }

  /// Never sort [MessageController.messages] in place — it is unmodifiable.
  List<MessageModel> _sortedMessagesCopy() {
    final sorted = List<MessageModel>.from(_messages);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Descending order (newest first)
    return sorted;
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.removeListener(_onMessageControllerTick);
    _scrollController.removeListener(_onMessageScroll);
    _messageController.dispose();
    _scrollController.dispose();
    AppLogger.d('[ChatScreen] dispose conversation=$_conversationId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = _isBlocked(context);

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
                        builder: (context, _) {
                          final sortedMessages = _sortedMessagesCopy();
                          return _buildMessageBody(sortedMessages);
                        },
                      ),
                    ),
                    ListenableBuilder(
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
                            if (_isDeleteMode)
                              _buildDeleteBottomBar()
                            else if (isBlocked)
                              _buildBlockedBottomBar()
                            else
                              ChatInputField(
                                onSendMessage: _sendMessage,
                                onSendImage: _sendImage,
                                isLoading: _isSending,
                              ),
                          ],
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
      reverse: true, // Optimizes chat loading and places index 0 at the bottom
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

    Widget bubble = MessageBubble(
      key: ValueKey(message.id),
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

    return Column(
      children: [
        if (index > 0) const SizedBox(height: 10), // When reverse: true, this adds space above the message (between older and newer)
        bubble,
        if (message.isPinned)
          PinnedMessageBanner(pinnedMessage: message, username: _userName),
      ],
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
