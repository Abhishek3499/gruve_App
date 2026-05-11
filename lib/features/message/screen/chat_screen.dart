import 'dart:ui';

import 'package:flutter/material.dart';

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

  bool _isSending = false;
  bool _hasCompletedInitialScroll = false;
  ReplyMessageModel? _activeReply;
  MessageModel? _pinnedMessage;

  bool _showPopup = false;
  MessageModel? _popupMessage;
  double _popupMessageBottom = 0;
  double _popupMessageTop = 0;
  Size _popupBubbleSize = Size.zero;

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
    return (widget.userOrConversation as dynamic).name ?? 'Unknown';
  }

  String get _userId {
    final explicitId = widget.receiverId?.trim();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }

    if (_isConversationModel) {
      return (widget.userOrConversation as ConversationModel).otherUser.id;
    }
    return (widget.userOrConversation as dynamic).id ?? '';
  }

  String get _conversationId {
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
    return (widget.userOrConversation as dynamic).profileImage;
  }

  List<MessageModel> get _messages => _messageController.messages;

  @override
  void initState() {
    super.initState();
    debugPrint('[ChatScreen] init user=$_userName conversation=$_conversationId');

    _messageController = MessageController(
      messageService: MessageService(),
      conversationId: _conversationId,
      receiverUserId: _userId,
    )..addListener(_handleMessageStateChanged);

    // Requirement: the messages API is called only after ChatScreen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[ChatScreen] Fetch messages requested for $_conversationId');
      _hasCompletedInitialScroll = false;
      _messageController.fetchInitialMessages();
    });
  }

  void _handleMessageStateChanged() {
    if (!mounted) return;
    setState(() {});

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

  void _showMessagePopup(
    MessageModel message,
    Offset globalPosition,
    Size bubbleSize,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    setState(() {
      _showPopup = true;
      _popupMessage = message;
      _popupBubbleSize = bubbleSize;
      _popupMessageTop = globalPosition.dy - statusBarHeight;
      _popupMessageBottom =
          globalPosition.dy + bubbleSize.height - statusBarHeight + 10;
    });
  }

  void _dismissPopup() {
    setState(() {
      _showPopup = false;
      _popupMessage = null;
    });
  }

  void _enterDeleteMode() {
    setState(() {
      _showPopup = false;
      _isDeleteMode = true;
      _selectedMessageIds.clear();
      if (_popupMessage != null) {
        _selectedMessageIds.add(_popupMessage!.id);
      }
      _popupMessage = null;
    });
  }

  void _exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _deleteSelectedMessages() {
    _messageController.removeMessages(_selectedMessageIds);
    setState(() {
      _isDeleteMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _sendMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    debugPrint('[ChatScreen] Sending local message to $_conversationId');
    final newMessage = MessageModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: trimmedText,
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
      replyTo: _activeReply?.originalMessage,
    );

    setState(() {
      _isSending = true;
      _activeReply = null;
    });
    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSending = false);
    });
  }

  void _sendImage(String imagePath) {
    debugPrint('[ChatScreen] Sending local image message to $_conversationId');
    final newMessage = MessageModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: '',
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
      imagePath: imagePath,
      replyTo: _activeReply?.originalMessage,
    );

    setState(() {
      _isSending = true;
      _activeReply = null;
    });
    _messageController.appendLocalMessage(newMessage);
    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSending = false);
    });
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    debugPrint('[ChatScreen] Message action=$action id=${message.id}');
    _dismissPopup();

    switch (action) {
      case MessageAction.reply:
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
        _enterDeleteMode();
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
    setState(() => _pinnedMessage = pinned);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_userName pinned a message')),
    );
  }

  void _clearReply() {
    setState(() => _activeReply = null);
  }

  List<MessageModel> _getSortedMessages() {
    final sorted = List<MessageModel>.from(_messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageStateChanged);
    _messageController.dispose();
    _scrollController.dispose();
    debugPrint('[ChatScreen] dispose conversation=$_conversationId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedMessages = _getSortedMessages();

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
                      onBack: () {
                        if (_isDeleteMode) {
                          _exitDeleteMode();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(child: _buildMessageBody(sortedMessages)),
                    if (_activeReply != null && !_isDeleteMode)
                      ReplyPreviewBar(
                        replyMessage: _activeReply!,
                        onClose: _clearReply,
                      ),
                    if (_isDeleteMode)
                      _buildDeleteBottomBar()
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
                      onTap: _dismissPopup,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                if (_showPopup && _popupMessage != null)
                  Positioned(
                    top: _popupMessageTop,
                    left: 0,
                    right: 0,
                    height: _popupBubbleSize.height,
                    child: IgnorePointer(
                      child: MessageBubble(
                        message: _popupMessage!,
                        onActionSelected: null,
                        onLongPress: null,
                      ),
                    ),
                  ),
                if (_showPopup && _popupMessage != null)
                  Positioned(
                    top: _popupMessageBottom + 4,
                    left: 16,
                    child: MessagePopupMenu(
                      selectedAction: null,
                      onActionSelected: (action) =>
                          _handleMessageAction(action, _popupMessage!),
                      onDeleteMode: _enterDeleteMode,
                      onDismiss: _dismissPopup,
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
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
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        return _buildMessageRow(message, index);
      },
    );
  }

  Widget _buildMessageRow(MessageModel message, int index) {
    final isSelected = _selectedMessageIds.contains(message.id);

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

    return Column(
      children: [
        if (index > 0) const SizedBox(height: 10),
        bubble,
        if (message.isPinned)
          PinnedMessageBanner(
            pinnedMessage: message,
            username: _userName,
          ),
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
}
