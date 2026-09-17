import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/message/presentation/controller/user_provider.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/message/domain/entities/conversation_model.dart';
import 'package:gruve_app/features/message/presentation/notifiers/message_notifier.dart';
import 'package:gruve_app/features/message/presentation/widgets/message_header.dart';
import 'package:gruve_app/features/message/presentation/widgets/message_card.dart';
import 'package:gruve_app/features/message/presentation/widgets/swipe_delete_background.dart';
import 'package:gruve_app/features/message/presentation/screens/chat_screen.dart';

import 'package:gruve_app/shared/widgets/shimmer/chat_shimmer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({super.key});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  bool _isLoadingMoreConversations = false;
  bool _startedUserPrefetch = false;
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();
  UserProvider? _userProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider ??= context.read<UserProvider>();
  }

  @override
  void initState() {
    super.initState();
    AppLogger.d('📱 [MessageScreen] Screen initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('[MessageScreen] Starting conversation fetch');
      unawaited(_fetchInitialData());
    });
  }

  @override
  void dispose() {
    ref.read(messageNotifierProvider.notifier).cancelActiveRequests();
    _userProvider?.cancelActiveRequests();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    _prefetchUsersForAvatarRow();
    await ref
        .read(messageNotifierProvider.notifier)
        .fetchConversations(refresh: true);
    AppLogger.d('[MessageScreen] Conversations loaded');
  }

  void _prefetchUsersForAvatarRow() {
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    if (userProvider.isLoading) return;

    if (_startedUserPrefetch || userProvider.hasInitialized) return;

    _startedUserPrefetch = true;
    unawaited(userProvider.fetchUsers(reason: 'initial'));
  }

  Future<void> _handleRefresh() async {
    AppLogger.d('🔄 [MessageScreen] Refresh started');

    // Clear cache timestamps to force fresh data
    final messageNotifier = ref.read(messageNotifierProvider.notifier);
    final userProvider = context.read<UserProvider>();

    await messageNotifier.refreshConversations();
    unawaited(userProvider.refreshUsers());

    AppLogger.d('✅ [MessageScreen] Refresh completed');
  }

  Future<bool> _showDeleteConfirmation(ConversationModel conversation) async {
    AppLogger.d(
      '🗑️ [MessageScreen] Showing delete confirmation for: ${conversation.otherUserName}',
    );
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF51829), fontSize: 16),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<bool> _deleteConversation(ConversationModel conversation) async {
    AppLogger.d(
      '🗑️ [MessageScreen] Deleting conversation: ${conversation.id} - ${conversation.otherUserName}',
    );
    final success = await ref
        .read(messageNotifierProvider.notifier)
        .deleteConversation(conversation.id);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete conversation'),
          backgroundColor: Color(0xFFF51829),
        ),
      );
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageNotifierProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF42174C),
            child: Column(
              children: [
                /// 🔥 HEADER + LIST OVERLAP AREA
                Expanded(
                  child: Stack(
                    children: [
                      /// HEADER
                      MessageHeader(),

                      /// MESSAGE LIST
                      Positioned(
                        top: 195,
                        left: 0,
                        right: 0,
                        bottom: 60,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C0B21),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(40),
                            ),
                          ),
                          child: _buildConversationList(messageState),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔥 FOOTER (original wala hi)
              ],
            ),
          ),
          // Loading overlay during deletion
          if (messageState.isDeletingConversation)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF72008D)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationList(MessageState messageState) {
    if (kDebugMode) {
      AppLogger.d(
        '🔍 [buildConversationList] isLoading: ${messageState.isLoading} | count: ${messageState.conversationCount}',
      );
    }

    // Show loading shimmer on initial load
    if (messageState.isLoading && !messageState.hasConversations) {
      return const ChatListShimmer(itemCount: 7);
    }

    // Show shimmer during refresh
    if (messageState.isRefreshing && !messageState.hasConversations) {
      return const ChatListShimmer(itemCount: 7);
    }

    // Show error state
    if (messageState.hasError && !messageState.hasConversations) {
      return _buildErrorState(messageState);
    }

    // Show empty state
    if (!messageState.hasConversations && !messageState.isLoading) {
      return _buildEmptyState();
    }

    // Show conversation list
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (_paginationTrigger.shouldLoadMoreFromMetrics(
          scrollInfo.metrics,
          isLoading:
              _isLoadingMoreConversations ||
              messageState.isLoading ||
              messageState.isLoadingMore ||
              messageState.isRefreshing,
          hasMore: messageState.hasMoreData,
        )) {
          _isLoadingMoreConversations = true;
          ref
              .read(messageNotifierProvider.notifier)
              .loadMoreConversations(reason: 'scroll')
              .then((_) {
                if (mounted) {
                  _isLoadingMoreConversations = false;
                }
              });
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        cacheExtent: 1000,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemCount:
            messageState.conversations.length +
            (messageState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= messageState.conversations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          final conversation = messageState.conversations[index];
          return RepaintBoundary(
            child: Dismissible(
              key: ValueKey(conversation.id),
              direction: DismissDirection.endToStart,
              background: SwipeDeleteBackground(onDelete: () {}),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  final confirmed = await _showDeleteConfirmation(conversation);
                  if (!confirmed || !mounted) return false;
                  return _deleteConversation(conversation);
                }
                return false;
              },
              child: MessageCard(
                conversation: conversation,
                onTap: () => _navigateToChat(conversation),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(MessageState messageState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            messageState.error ?? 'Something went wrong',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(messageNotifierProvider.notifier).fetchConversations(),
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
    AppLogger.d(
      '💬 [MessageScreen] Navigating to chat with: ${conversation.otherUserName} (${conversation.id})',
    );
    final messageNotifier = ref.read(messageNotifierProvider.notifier);
    messageNotifier.markConversationAsRead(conversation.id);

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

    if (!mounted) return;

    if (shouldRefresh == true) {
      AppLogger.d('🔄 [MessageScreen] Refreshing after block action');
      messageNotifier.removeConversation(conversation.id);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _handleRefresh();
      });
    } else {
      AppLogger.d(
        '🔄 [MessageScreen] User returned from ChatScreen - refreshing list',
      );
      unawaited(messageNotifier.fetchConversations(refresh: true));
    }
  }
}
