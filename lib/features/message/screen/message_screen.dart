import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../widgets/message_header.dart';
import '../widgets/message_card.dart';
import '../widgets/swipe_delete_background.dart';
import '../data/dummy_messages.dart';
import '../presentation/provider/user_provider.dart';
import '../../../../core/network/api_client.dart';
import '../data/datasource/user_remote_datasource.dart';
import '../data/repository/user_repository_impl.dart';
import '../domain/repository/user_repository.dart';
import '../../../../core/widgets/shimmer/chat_shimmer.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<ChatUser> _chatUsers = [];
  // ✅ Track initial load separately from refresh
  // isInitialLoading = true only on first open, shows shimmer
  // _isRefreshing = true on pull-to-refresh, shows RefreshIndicator
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  void _loadChatUsers() {
    // Simulate initial load delay so shimmer is visible
    // Replace this Future.delayed with your real API call when ready
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _chatUsers = DummyMessages.getChatUsers();
        _isInitialLoading = false;
      });
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      // Refresh users from API
      await context.read<UserProvider>().fetchUsers();
      
      // Reload chat users (dummy data for now)
      _loadChatUsers();
      
      debugPrint('🔄 [MessageScreen] Pull-to-refresh completed');
    } catch (e) {
      debugPrint('💥 [MessageScreen] Pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  void _showDeleteConfirmation(ChatUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B36),
        title: const Text(
          'Delete Conversation',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete conversation with ${user.name}?',
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
              _deleteConversation(user);
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

  void _deleteConversation(ChatUser user) {
    setState(() {
      _chatUsers.removeWhere((chatUser) => chatUser.id == user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, UserRemoteDataSource>(
          update: (_, apiClient, __) => UserRemoteDataSource(apiClient),
        ),
        ProxyProvider<UserRemoteDataSource, UserRepository>(
          update: (_, dataSource, __) => UserRepositoryImpl(dataSource),
        ),
        ChangeNotifierProxyProvider<UserRepository, UserProvider>(
          create: (_) => UserProvider(
            UserRepositoryImpl(UserRemoteDataSource(ApiClient())),
          ),
          update: (_, repository, __) => UserProvider(repository),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF1C0B21),
        resizeToAvoidBottomInset: true,
        body: RefreshIndicator(
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
                    const MessageHeader(),

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
                        child: _isInitialLoading
                            // ✅ SHIMMER on first load — shows chat row shapes
                            // so user knows what's coming before data arrives
                            ? const ChatListShimmer(itemCount: 7)
                            : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _chatUsers.length,
                          itemBuilder: (context, index) {
                            final user = _chatUsers[index];
                            return Dismissible(
                              key: Key(user.id),
                              direction: DismissDirection.endToStart,
                              background: SwipeDeleteBackground(
                                onDelete: () => _showDeleteConfirmation(user),
                              ),
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  _showDeleteConfirmation(user);
                                }
                              },
                              child: MessageCard(
                                title: user.name,
                                message: user.lastMessage,
                                time: user.lastMessageTime,
                                unreadCount: user.unreadCount,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// 🔥 FOOTER (original wala hi)
            ],
          ),
        ),
      ),
    );
  }
}
