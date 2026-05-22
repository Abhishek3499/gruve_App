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
         conversationId != null || userOrConversation != null,
         'Either conversationId or userOrConversation must be provided',
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

    return userData.name?.toString() ?? 'Unknown';
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

    return userData.id?.toString() ?? '';
  }

  String get _conversationId {
    if (_resolvedConversationId != null && _resolvedConversationId!.isNotEmpty) {
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
      return legacyUser.conversationId?.toString() ?? '';
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

    return userData.profileImage?.toString();
  }

  List<MessageModel> get _messages => _messageController.messages;
  bool _isBlocked(BuildContext context) {
    return context.watch<BlockProvider>().isBlocked(_userId);
  }

  @override
  void initState() {
    super.initState();

    // Socket connection is now managed automatically without heartbeat context

    debugPrint(
      '[ChatScreen] init user=$_userName conversation=$_conversationId',
    );

    _messageController = MessageController(
      messageService: MessageService(),
      conversationId: _conversationId,
      receiverUserId: _userId,
      onConversationIdChanged: (conversationId) {
        _resolvedConversationId = conversationId;
        debugPrint(
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
        debugPrint(
          '🔒 [ChatScreen] Block state synced from backend = $isBlocked',
        );
      } catch (e) {
        debugPrint('⚠️ [ChatScreen] Failed to sync block state: $e');
      }
    });
    // Requirement: the messages API is called only after ChatScreen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('[ChatScreen] Fetch messages requested for $_conversationId');
      _hasCompletedInitialScroll = false;
      _messageController.fetchInitialMessages();
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

    if (_scrollController.position.pixels <= 80) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (!_scrollController.hasClients) return;

    _isLoadingOlderMessages = true;
    final beforeMaxExtent = _scrollController.position.maxScrollExtent;
    final beforePixels = _scrollController.position.pixels;

    await _messageController.loadMoreMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        _isLoadingOlderMessages = false;
        return;
      }

      final extentDelta =
          _scrollController.position.maxScrollExtent - beforeMaxExtent;
      if (extentDelta > 0) {
        _scrollController.jumpTo(beforePixels + extentDelta);
      }
      _isLoadingOlderMessages = false;
    });
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
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _initializeSocketListener() {
    if (_socketSubscription != null) {
      debugPrint('🎧 SOCKET LISTENER ALREADY ACTIVE');
      return;
    }

    debugPrint('🎧 SOCKET LISTENER STARTED');

    _socketSubscription = _socketService.messageStream.listen((data) {
      debugPrint('🔥 SOCKET DATA => $data');

      try {
        final incomingConversationId = data['conversation_id'];

        if (incomingConversationId != _conversationId) {
          return;
        }

        final messageData = data['data'] as Map<String, dynamic>? ?? data;
        _messageController.addRealtimeMessage(messageData);

        debugPrint('✅ REALTIME MESSAGE ADDED');

        _scrollToBottom();
      } catch (e) {
        debugPrint('💥 SOCKET ERROR => $e');
      }
    });
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

    debugPrint(
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
    );

    if (!mounted) return;
    setState(() {
      _isSending = true;
      _activeReply = null;
    });

    // Step 1: Optimistic local append
    debugPrint('[ChatScreen] 📝 Step 1: Local message appended id=$localId');
    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    // Step 2: Attempt backend persistence with timeout protection
    try {
      debugPrint('[ChatScreen] 🌐 Step 2: Starting backend send...');

      await _sendToBackend(trimmedText).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Send timeout after 15s'),
      );

      debugPrint('[ChatScreen] ✅ Step 3: Backend send SUCCESS');
    } catch (e) {
      debugPrint('[ChatScreen] ❌ Step 3: Backend send FAILED: $e');
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
      debugPrint('[ChatScreen] 🏁 SEND FLOW COMPLETE');
    }
  }

  Future<void> _sendToBackend(String content) async {
    debugPrint('[ChatScreen] 🔄 Backend send: Trying WebSocket first...');

    // Step 2a: Try WebSocket send with timeout
    final wsSuccess = await _tryWebSocketSend(content).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint('[ChatScreen] WebSocket send timed out after 12s');
        return false;
      },
    );

    if (wsSuccess) {
      debugPrint('[ChatScreen] ✅ WebSocket send SUCCESS');
      return;
    }

    // Current backend sends chat messages over WebSocket. The REST collection
    // endpoint allows GET, but POST returns 405 Method Not Allowed.
    debugPrint('[ChatScreen] WebSocket unavailable; REST send skipped');
    throw Exception('Message connection unavailable. Please try again.');
  }

  Future<bool> _tryWebSocketSend(String content) async {
    try {
      debugPrint('[ChatScreen] 📡 WebSocket send attempt start');
      final socketService = SocketService();

      if (!socketService.isConnected) {
        debugPrint('[ChatScreen] ⚠️ WebSocket NOT CONNECTED');
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          debugPrint('[ChatScreen] No token available for WebSocket reconnect');
          return false;
        }

        await socketService.connect(accessToken);
        final connected = await _waitForSocketConnection(socketService);
        if (!connected) {
          debugPrint('[ChatScreen] WebSocket reconnect did not complete');
          return false;
        }
      }

      final sent = socketService.sendMessage(
        conversationId: _conversationId,
        message: content,
      );

      debugPrint('[ChatScreen] 📡 WebSocket send result: $sent');
      return sent;
    } catch (e) {
      debugPrint('[ChatScreen] ❌ WebSocket send exception: $e');
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
    debugPrint('[ChatScreen] 🖼️ Image send not yet implemented: $imagePath');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image sending coming soon!')));
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    debugPrint('[ChatScreen] 🎯 Message action=$action id=${message.id}');
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
          debugPrint('[ChatScreen] 🗑️ 👤 Own message - showing delete confirmation');
          _showDeleteConfirmation(message);
        } else {
          debugPrint('[ChatScreen] ⚠️ 🚫 Not own message - cannot delete');
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
    debugPrint('🗑️ [ChatScreen] 💬 Showing delete confirmation for message: ${message.id}');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Message?',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This message will be deleted for you. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🗑️ [ChatScreen] ❌ Delete cancelled by user');
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              debugPrint('🗑️ [ChatScreen] ✅ Delete confirmed by user');
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF51829).withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF51829), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      debugPrint('🗑️ [ChatScreen] 🚀 User confirmed - proceeding with delete');
      await _deleteSingleMessage(message);
    } else {
      debugPrint('🗑️ [ChatScreen] ⚠️ Delete not confirmed or context unmounted');
    }
  }

  /// Delete a single message
  Future<void> _deleteSingleMessage(MessageModel message) async {
    debugPrint('🗑️ [ChatScreen] 🚀 Starting delete process for message: ${message.id}');
    debugPrint('💬 [ChatScreen] 📝 Message text: ${message.text.substring(0, message.text.length.clamp(0, 50))}${message.text.length > 50 ? "..." : ""}');
    
    try {
      debugPrint('📡 [ChatScreen] 🌐 Calling MessageController.deleteMessage...');
      final success = await _messageController.deleteMessage(message.id);

      if (!mounted) {
        debugPrint('⚠️ [ChatScreen] ❌ Context unmounted after delete');
        return;
      }

      if (success) {
        debugPrint('✅ [ChatScreen] 🎉 Message deleted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint('❌ [ChatScreen] ⚠️ Delete failed - showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('💥 [ChatScreen] ❌ Error deleting message: $e');
      
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
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.removeListener(_onMessageControllerTick);
    _scrollController.removeListener(_onMessageScroll);
    _messageController.dispose();
    _scrollController.dispose();
    debugPrint('[ChatScreen] dispose conversation=$_conversationId');
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
      itemCount:
          sortedMessages.length + (_messageController.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_messageController.isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
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

        final messageIndex = index - (_messageController.isLoadingMore ? 1 : 0);
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
        if (index > 0) const SizedBox(height: 10),
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
