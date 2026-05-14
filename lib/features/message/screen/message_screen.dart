import 'package:flutter/material.dart';
import 'package:gruve_app/features/message/presentation/provider/user_provider.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../providers/message_provider.dart';
import '../widgets/message_header.dart';
import '../widgets/message_card.dart';
import '../widgets/swipe_delete_background.dart';
import '../screen/chat_screen.dart';

import '../../../core/widgets/shimmer/chat_shimmer.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('📱 [MessageScreen] Screen initialized');
    // Fetch conversations on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔄 [MessageScreen] Starting initial conversation fetch');
      context.read<MessageProvider>().fetchConversations();
    });
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 [MessageScreen] Refresh started');

    await Future.wait([
      context.read<MessageProvider>().refreshConversations(),
      context.read<UserProvider>().refreshUsers(),
    ]);

    debugPrint('✅ [MessageScreen] Refresh completed');
  }

  void _showDeleteConfirmation(ConversationModel conversation) {
    debugPrint(
      '🗑️ [MessageScreen] Showing delete confirmation for: ${conversation.otherUserName}',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B36),
        title: const Text(
          'Delete Conversation',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete conversation with ${conversation.otherUserName}?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF72008D), fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversation);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF51829), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteConversation(ConversationModel conversation) {
    debugPrint(
      '🗑️ [MessageScreen] Deleting conversation: ${conversation.id} - ${conversation.otherUserName}',
    );
    context.read<MessageProvider>().deleteConversation(conversation.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.white,
        backgroundColor: const Color(0xFF42174C),
        child: Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            return Column(
              children: [
                /// 🔥 HEADER + LIST OVERLAP AREA
                Expanded(
                  child: Stack(
                    children: [
                      /// HEADER
                      MessageHeader(),

                      /// MESSAGE LIST
                      Positioned(
                        top: 240,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C0B21),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(40),
                            ),
                          ),
                          child: _buildConversationList(messageProvider),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔥 FOOTER (original wala hi)
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationList(MessageProvider messageProvider) {
    debugPrint(
      '🔍 [buildConversationList] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    debugPrint(
      '🔍 [buildConversationList] isLoading: ${messageProvider.isLoading} | isRefreshing: ${messageProvider.isRefreshing}',
    );
    debugPrint(
      '📊 [buildConversationList] conversationCount: ${messageProvider.conversationCount} | hasMore: ${messageProvider.hasMoreData} | page: ${messageProvider.currentPage}',
    );
    debugPrint(
      '📩 [buildConversationList] totalUnread: ${messageProvider.totalUnreadCount}',
    );

    if (messageProvider.hasError) {
      debugPrint('❌ [buildConversationList] error: ${messageProvider.error}');
    }
    if (!messageProvider.hasConversations && !messageProvider.isLoading) {
      debugPrint('⚠️ [buildConversationList] conversations list is NULL/EMPTY');
    }
    if (messageProvider.hasConversations) {
      final ids = messageProvider.conversations
          .map((c) => c.id)
          .take(5)
          .toList();
      final unreadCounts = messageProvider.conversations
          .take(5)
          .map((c) => '${c.id.substring(0, 6)}:${c.unreadCount}')
          .toList();
      debugPrint('💬 [buildConversationList] conversationIDs (first 5): $ids');
      debugPrint(
        '🔔 [buildConversationList] unreadCounts (first 5): $unreadCounts',
      );
    }

    // Show loading shimmer on initial load
    if (messageProvider.isLoading && !messageProvider.hasConversations) {
      debugPrint('🚀 [buildConversationList] → showing shimmer (initial load)');
      return const ChatListShimmer(itemCount: 7);
    }

    // Show error state
    if (messageProvider.hasError && !messageProvider.hasConversations) {
      debugPrint('❌ [buildConversationList] → showing error state');
      return _buildErrorState(messageProvider);
    }

    // Show empty state
    if (!messageProvider.hasConversations && !messageProvider.isLoading) {
      debugPrint('⚠️ [buildConversationList] → showing empty state');
      return _buildEmptyState();
    }

    // Show conversation list
    debugPrint(
      '✅ [buildConversationList] → rendering ${messageProvider.conversationCount} conversations',
    );
    
    bool _isLoadingMore = false;
    
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // Prevent pagination spam with threshold and loading guard
        if (!_isLoadingMore &&
            messageProvider.hasMoreData &&
            !messageProvider.isLoading &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _isLoadingMore = true;
          debugPrint(
            '⬇️ [MessageScreen] Loading more conversations',
          );
          messageProvider.loadMoreConversations().then((_) {
            _isLoadingMore = false;
          });
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messageProvider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = messageProvider.conversations[index];
          return Dismissible(
            key: ValueKey(conversation.id),
            direction: DismissDirection.endToStart,
            background: SwipeDeleteBackground(
              onDelete: () => _showDeleteConfirmation(conversation),
            ),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _showDeleteConfirmation(conversation);
              }
            },
            child: MessageCard(
              conversation: conversation,
              onTap: () => _navigateToChat(conversation),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(MessageProvider messageProvider) {
    debugPrint('💥 [MessageScreen] Building error state widget');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            messageProvider.error ?? 'Something went wrong',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => messageProvider.fetchConversations(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF72008D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    debugPrint('📭 [MessageScreen] Building empty state widget');
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 48),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation to see it here',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(ConversationModel conversation) async {
    debugPrint(
      '💬 [MessageScreen] Navigating to chat with: ${conversation.otherUserName} (${conversation.id})',
    );
    context.read<MessageProvider>().markConversationAsRead(conversation.id);

    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          receiverId: conversation.otherUser.id,
          userName: conversation.otherUserName,
          profileImage: conversation.otherUser.avatar,
          userOrConversation: conversation,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      debugPrint('🔄 [MessageScreen] Refreshing after block action');
      context.read<MessageProvider>().removeConversation(conversation.id);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _handleRefresh();
      });
    }
  }
}
