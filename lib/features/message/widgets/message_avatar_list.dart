import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/message_avatar.dart';
import '../presentation/provider/user_provider.dart';
import '../../../../widgets/message_avatar_skeleton.dart';

class MessageAvatarList extends StatefulWidget {
  const MessageAvatarList({super.key});

  @override
  State<MessageAvatarList> createState() => _MessageAvatarListState();
}

class _MessageAvatarListState extends State<MessageAvatarList> {
  late final ScrollController _scrollController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // No need to manually fetch users anymore - UserProvider auto-fetches in constructor
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 100.0; // Load more when 100px from end

    if (maxScroll - currentScroll <= delta) {
      debugPrint('📜 [MessageAvatarList] Near end of scroll, loading more...');
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    final provider = context.read<UserProvider>();
    
    // Prevent duplicate calls
    if (provider.isFetchingMore || !provider.hasNext) {
      debugPrint('⏸️ [MessageAvatarList] Skipping loadMore - isFetchingMore: ${provider.isFetchingMore}, hasNext: ${provider.hasNext}');
      return;
    }

    debugPrint('📜 [MessageAvatarList] Loading more users...');
    await provider.fetchUsers(loadMore: true);
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await context.read<UserProvider>().refreshUsers();
      debugPrint('🔄 [MessageAvatarList] Pull-to-refresh completed');
    } catch (e) {
      debugPrint('💥 [MessageAvatarList] Pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, p, child) {
        debugPrint('🔄 [MessageAvatarList] UI rebuilding — isLoading: ${p.isLoading}, users: ${p.users.length}, isFetchingMore: ${p.isFetchingMore}');
        
        if (p.isLoading && p.users.isEmpty) {
          // Initial loading state - show skeleton
          return const MessageAvatarSkeleton(avatarCount: 6);
        } else if (p.users.isEmpty && !p.isLoading) {
          // Empty state
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF42174C),
            child: const SizedBox(
              height: 90,
              child: Center(child: Text('No users found')),
            ),
          );
        } else {
          // Users loaded - show list with pagination
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF42174C),
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: p.users.length + (p.isFetchingMore ? 1 : 0), // Add loader at end if fetching more
                itemBuilder: (context, index) {
                  // Show loading indicator at the end when fetching more
                  if (index == p.users.length && p.isFetchingMore) {
                    return const MessageAvatarPaginationSkeleton();
                  }

                  // Show user avatar
                  final user = p.users[index];
                  return MessageAvatar(
                    name: user.username,
                    imageUrl: user.profilePicture ?? '',   // empty string = null fallback handled in MessageAvatar
                    isOnline: false,                        // API doesn't return isOnline, default false
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
