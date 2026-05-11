import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../controllers/message_controller.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/reply_message_model.dart';
import '../services/message_service.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_popup_menu.dart';

import '../widgets/reply_preview_bar.dart';
import '../utils/user_display_helper.dart';
import '../../../core/widgets/skeletons/chat_skeleton.dart';
import '../../../../services/socket_service.dart';

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
    required this.userOrConversation,
    this.conversationId,
    this.receiverId,
    this.userName,
    this.profileImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late final MessageController _messageController;

  bool _isDeleteMode = false;
  final Set<String> _selectedMessageIds = {};
  bool _hasCompletedInitialScroll = false;
  ReplyMessageModel? _activeReply;
  bool _isSending = false;

  bool get _isConversationModel =>
      widget.userOrConversation is ConversationModel;

  bool get _useExplicitData => widget.conversationId != null;

  String get _userName {
    // Use centralized UserDisplayHelper for consistent naming
    return UserDisplayHelper.getDisplayNameForLegacyUser(
      widget.userOrConversation,
    );
  }

  String get _userId {
    // Use centralized UserDisplayHelper for consistent ID extraction
    return UserDisplayHelper.getUserIdForUser(widget.userOrConversation);
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

    // Priority 2: Use centralized helper
    return UserDisplayHelper.getProfileImageForUser(widget.userOrConversation);
  }

  List<MessageModel> get _messages => _messageController.messages;

  @override
  void initState() {
    super.initState();

    // Validate required data
    if (_conversationId.isEmpty) {
      debugPrint('❌ [ChatScreen] ERROR: Conversation ID is empty');
      _showErrorAndPop('Invalid conversation: Missing conversation ID');
      return;
    }

    if (_userId.isEmpty) {
      debugPrint('❌ [ChatScreen] ERROR: User ID is empty');
      _showErrorAndPop('Invalid conversation: Missing user ID');
      return;
    }

    if (_userName.isEmpty || _userName == 'Unknown') {
      debugPrint('⚠️ [ChatScreen] WARNING: User name is missing or unknown');
    }

    debugPrint(
      '✅ [ChatScreen] init user=$_userName conversation=$_conversationId',
    );
    debugPrint('🖼️ [ChatScreen] profileImage=${_userAvatar ?? "none"}');

    _messageController = MessageController(
      messageService: MessageService(),
      conversationId: _conversationId,
      receiverUserId: _userId,
    )..addListener(_handleMessageStateChanged);

    // Requirement: messages API is called only after ChatScreen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('[ChatScreen] Fetch messages requested for $_conversationId');
      _hasCompletedInitialScroll = false;
      _messageController.fetchInitialMessages();
    });
  }

  void _showErrorAndPop(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      debugPrint('⚠️ [ChatScreen] sendMessage: Empty text, ignoring');
      return;
    }

    // If conversationId is empty, we need to create a conversation first
    if (_conversationId.isEmpty) {
      _createConversationAndSendMessage(trimmedText);
      return;
    }

    debugPrint(
      '📤 [ChatScreen] Sending message to $_conversationId: "${trimmedText.substring(0, 50)}${trimmedText.length > 50 ? "..." : ""}"',
    );

    try {
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

      // Send message via WebSocket for real-time delivery
      SocketService().sendMessage(
        conversationId: _conversationId,
        message: trimmedText,
      );

      // Also add to local list for immediate UI feedback
      _messageController.appendLocalMessage(newMessage);
      _scrollToBottom();

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _isSending = false);
        debugPrint('✅ [ChatScreen] Message send completed via WebSocket');
      });
    } catch (e) {
      debugPrint('❌ [ChatScreen] Error sending message: $e');
      if (mounted) {
        setState(() => _isSending = false);
        _showErrorSnackBar('Failed to send message');
      }
    }
  }

  /// Create conversation first, then send message
  /// This handles the case when user navigates directly to chat without existing conversation
  Future<void> _createConversationAndSendMessage(String messageText) async {
    try {
      debugPrint(
        '🔨 [ChatScreen] Creating conversation for message: "${messageText.substring(0, 50)}${messageText.length > 50 ? "..." : ""}"',
      );

      // Check WebSocket connection status first
      final socketState = SocketService().state;
      debugPrint('🔌 [ChatScreen] WebSocket state: $socketState');

      // Check if user is authenticated
      debugPrint(
        '🔑 [ChatScreen] User ID: $_userId, Conversation ID: $_conversationId',
      );

      // Create conversation using ConversationController
      final conversationController = ConversationController(MessageService());
      final conversation = await conversationController.createOrGetConversation(
        _userId,
      );

      if (!mounted) return;

      // Update state with new conversation data
      setState(() {
        // This will update all the getters (_conversationId, _userName, etc.)
        // The userOrConversation will now be the new ConversationModel
      });

      debugPrint('✅ [ChatScreen] Conversation created: ${conversation.id}');
      debugPrint(
        '👤 [ChatScreen] Conversation user data: ${conversation.otherUser.name}, ID: ${conversation.otherUser.id}',
      );

      // Now send the message using the new conversation ID
      _sendMessageWithConversationId(messageText, conversation.id);
    } catch (e) {
      debugPrint('❌ [ChatScreen] Error creating conversation: $e');
      _showErrorSnackBar('Failed to create conversation');
    }
  }

  /// Send message with valid conversation ID
  /// This is the actual message sending logic using WebSocket
  void _sendMessageWithConversationId(
    String messageText,
    String conversationId,
  ) {
    final trimmedText = messageText.trim();
    if (trimmedText.isEmpty) {
      debugPrint('⚠️ [ChatScreen] sendMessage: Empty text, ignoring');
      return;
    }

    debugPrint(
      '📤 [ChatScreen] Sending message to $conversationId: "${trimmedText.substring(0, 50)}${trimmedText.length > 50 ? "..." : ""}"',
    );
    debugPrint(
      '🔌 [ChatScreen] Message text length: ${trimmedText.length}, conversationId: $conversationId',
    );

    try {
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

      // Send message via WebSocket for real-time delivery
      debugPrint('📡 [ChatScreen] Calling SocketService.sendMessage()');
      SocketService().sendMessage(
        conversationId: conversationId,
        message: trimmedText,
      );
      debugPrint(
        '📡 [ChatScreen] SocketService.sendMessage() called successfully',
      );

      // Also add to local list for immediate UI feedback
      _messageController.appendLocalMessage(newMessage);
      _scrollToBottom();
      debugPrint('📥 [ChatScreen] Local message added: ${newMessage.id}');

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _isSending = false);
        debugPrint('✅ [ChatScreen] Message send completed via WebSocket');
      });
    } catch (e) {
      debugPrint('❌ [ChatScreen] Error sending message: $e');
      if (mounted) {
        setState(() => _isSending = false);
        _showErrorSnackBar('Failed to send message');
      }
    }
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
      debugPrint('✅ [ChatScreen] Image message send completed');
    });
  }

  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedMessageIds.clear();
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

  void _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    try {
      setState(() => _isDeleteMode = false);
      // TODO: Implement actual message deletion via API
      debugPrint(
        '🗑️ [ChatScreen] Deleting ${_selectedMessageIds.length} messages',
      );

      _selectedMessageIds.clear();
    } catch (e) {
      debugPrint('❌ [ChatScreen] Error deleting messages: $e');
      _showErrorSnackBar('Failed to delete messages');
    }
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    switch (action) {
      case MessageAction.reply:
        setState(() {
          _activeReply = ReplyMessageModel(originalMessage: message);
        });
        break;
      case MessageAction.pin:
        setState(() {
          // TODO: Implement actual pinning via API
          debugPrint('📌 [ChatScreen] Pinning message ${message.id}');
        });
        break;
      case MessageAction.delete:
        _deleteSelectedMessages();
        break;
    }
  }

  void _showMessagePopup(String message, Offset globalPos, Size size) {
    // TODO: Implement message popup
  }

  void _dismissPopup() {
    // TODO: Implement popup dismissal
  }

  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedMessageIds.clear();
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

  void _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    try {
      setState(() => _isDeleteMode = false);
      // TODO: Implement actual message deletion via API
      debugPrint(
        '🗑️ [ChatScreen] Deleting ${_selectedMessageIds.length} messages',
      );

      _selectedMessageIds.clear();
    } catch (e) {
      debugPrint('❌ [ChatScreen] Error deleting messages: $e');
      _showErrorSnackBar('Failed to delete Messages');
    }
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    switch (action) {
      case MessageAction.reply:
        setState(() {
          _activeReply = ReplyMessageModel(originalMessage: message);
        });
        break;
      case MessageAction.pin:
        setState(() {
          // TODO: Implement actual pinning via API
          debugPrint('📌 [ChatScreen] Pinning message ${message.id}');
        });
        break;
      case MessageAction.delete:
        _deleteSelectedMessages();
        break;
    }
  }

  void _showMessagePopup(String message, Offset globalPos, Size size) {
    // TODO: Implement message popup
  }

  void _dismissPopup() {
    // TODO: Implement popup dismissal
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageStateChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<MessageModel> get sortedMessages {
    final messages = _messages;
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Widget _buildMessageBody(List<MessageModel> sortedMessages) {
    // Instagram/WhatsApp-style shimmer loading UX
    //
    // Shimmer Lifecycle:
    // 1. User opens chat → isInitialLoading=true, messages=[] → Show shimmer
    // 2. API completes → isInitialLoading=false, messages=[data] → Show real messages
    // 3. Pagination → isInitialLoading=false, messages=[data] → No shimmer (existing messages stay)
    // 4. Realtime updates → isInitialLoading=false, messages=[data+new] → No shimmer (smooth transition)
    // 5. Pull-to-refresh → isInitialLoading=false, messages=[data] → No shimmer (refresh indicator handles it)
    if (_messageController.isInitialLoading && sortedMessages.isEmpty) {
      return const ChatShimmerSkeleton();
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
          _showMessagePopup(message.content, globalPos, size),
    );

    if (_isDeleteMode) {
      bubble = MessageWithCheckbox(
        message: bubble,
        isSelected: isSelected,
        onTap: () => _toggleMessageSelection(message.id),
        onCheckboxChanged: (_) => _toggleMessageSelection(message.id),
      );
    }

    return bubble;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Unable to load messages',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _messageController.retry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: const TextStyle(color: Colors.white70, version: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation!',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  ReplyMessageModel? _pinnedMessage;

  @override
  Widget build(BuildContext context) {
    final sortedMessages = _messages;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2),
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(
              userOrConversation: widget.userOrConversation,
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
                onCancel: () => setState(() => _activeReply = null),
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
      ),
    );
  }

  Widget _buildDeleteBottomBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF720E8E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Delete for you (${_selectedMessageIds.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _deleteSelectedMessages,
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
