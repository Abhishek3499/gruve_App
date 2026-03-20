import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/reply_message_model.dart';
import '../data/dummy_messages.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_popup_menu.dart';
import '../widgets/reply_preview_bar.dart';
import '../widgets/pinned_message_banner.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  ReplyMessageModel? _activeReply;
  MessageModel? _pinnedMessage;

  // ── Popup / blur state ──
  bool _showPopup = false;
  MessageModel? _popupMessage;
  double _popupMessageBottom = 0;
  double _popupMessageTop = 0; // ← top of pressed bubble
  Size _popupBubbleSize = Size.zero; // ← size of pressed bubble

  // ── Delete mode state ──
  bool _isDeleteMode = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      _messages = DummyMessages.getChatMessages(widget.user.id);
    });
  }

  // ── Show popup on long press ──
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
      // top of the bubble inside SafeArea
      _popupMessageTop = globalPosition.dy - statusBarHeight;
      // bottom of the bubble inside SafeArea
      _popupMessageBottom =
          globalPosition.dy + bubbleSize.height - statusBarHeight + 10;
    });
  }

  // ── Dismiss popup ──
  void _dismissPopup() {
    setState(() {
      _showPopup = false;
      _popupMessage = null;
    });
  }

  // ── Enter delete mode ──
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

  // ── Exit delete mode ──
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
    setState(() {
      _messages.removeWhere((msg) => _selectedMessageIds.contains(msg.id));
      _isDeleteMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
      replyTo: _activeReply?.originalMessage,
    );
    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
      _activeReply = null;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
    });
  }

  void _sendImage(String imagePath) {
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      timestamp: DateTime.now(),
      isSent: true,
      senderId: 'me',
      imagePath: imagePath,
      replyTo: _activeReply?.originalMessage,
    );
    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
      _activeReply = null;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
    });
  }

  void _handleMessageAction(MessageAction action, MessageModel message) {
    _dismissPopup();
    switch (action) {
      case MessageAction.reply:
        setState(() {
          _activeReply = ReplyMessageModel(
            originalMessage: message,
            username: message.isSent ? 'yourself' : widget.user.name,
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
        setState(() {
          if (_pinnedMessage != null) {
            final idx = _messages.indexWhere((m) => m.id == _pinnedMessage!.id);
            if (idx != -1)
              _messages[idx] = _messages[idx].copyWith(isPinned: false);
          }
          final idx = _messages.indexWhere((m) => m.id == message.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(isPinned: true);
            _pinnedMessage = _messages[idx];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.name} pinned a message')),
        );
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

  void _clearReply() => setState(() => _activeReply = null);

  List<MessageModel> _getSortedMessages() {
    final sorted = List<MessageModel>.from(_messages);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.timestamp.compareTo(b.timestamp);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedMessages = _getSortedMessages();

    return WillPopScope(
      onWillPop: () async {
        if (_isDeleteMode) {
          _exitDeleteMode();
          return false;
        }
        return true;
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
                // ── Layer 1: Main chat layout ──
                Column(
                  children: [
                    ChatHeader(
                      user: widget.user,
                      onBack: () {
                        if (_isDeleteMode) {
                          _exitDeleteMode();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sortedMessages.length,
                        itemBuilder: (context, index) {
                          final message = sortedMessages[index];
                          final isSelected = _selectedMessageIds.contains(
                            message.id,
                          );

                          Widget bubble = ChatBubble(
                            message: message,
                            onActionSelected: (action) =>
                                _handleMessageAction(action, message),
                            onLongPress: (globalPos, size) =>
                                _showMessagePopup(message, globalPos, size),
                          );

                          if (_isDeleteMode) {
                            bubble = MessageWithCheckbox(
                              message: bubble,
                              isSelected: isSelected,
                              onTap: () => _toggleMessageSelection(message.id),
                              onCheckboxChanged: (_) =>
                                  _toggleMessageSelection(message.id),
                            );
                          }

                          if (message.isPinned) {
                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 10),
                                bubble,
                                PinnedMessageBanner(
                                  pinnedMessage: message,
                                  username: widget.user.name,
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              if (index > 0) const SizedBox(height: 10),
                              bubble,
                            ],
                          );
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
                    else
                      ChatInputField(
                        onSendMessage: _sendMessage,
                        onSendImage: _sendImage,
                        isLoading: _isLoading,
                      ),
                  ],
                ),

                // ── Layer 2: Blur — poora background blur hoga ──
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

                // ── Layer 3: Pressed message — blur ke upar, clear dikhega ──
                if (_showPopup && _popupMessage != null)
                  Positioned(
                    top: _popupMessageTop,
                    left: 0,
                    right: 0,
                    height: _popupBubbleSize.height,
                    child: IgnorePointer(
                      // non-interactive — sirf display ke liye
                      child: ChatBubble(
                        message: _popupMessage!,
                        onActionSelected: null,
                        onLongPress: null,
                      ),
                    ),
                  ),

                // ── Layer 4: Popup menu — sabse upar ──
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

  // Widget _buildDeleteModeHeader() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     child: Row(
  //       children: [
  //         GestureDetector(
  //           onTap: _exitDeleteMode,
  //           child: const Icon(Icons.close, color: Colors.white, size: 24),
  //         ),
  //         const SizedBox(width: 16),
  //         Text(
  //           '${_selectedMessageIds.length} selected',
  //           style: const TextStyle(
  //             color: Colors.white,
  //             fontSize: 18,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
