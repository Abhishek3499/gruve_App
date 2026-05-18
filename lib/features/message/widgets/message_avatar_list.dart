import 'package:flutter/material.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:provider/provider.dart';

import '../widgets/message_avatar.dart';
import '../presentation/provider/user_provider.dart';
import '../utils/user_display_helper.dart';
import '../../../../widgets/message_avatar_skeleton.dart';

class MessageAvatarList extends StatefulWidget {
  const MessageAvatarList({super.key});

  @override
  State<MessageAvatarList> createState() => _MessageAvatarListState();
}

class _MessageAvatarListState extends State<MessageAvatarList> {
  final SocketService _socketService = SocketService();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    debugPrint('🚀 [MessageAvatarList] Initialized');
  }

  @override
  void dispose() {
    debugPrint('🗑️ [MessageAvatarList] Disposed');

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<UserProvider>();

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    const delta = 100.0;

    if (maxScroll - currentScroll <= delta) {
      debugPrint('📜 [MessageAvatarList] Near end reached → load more users');

      if (!provider.isFetchingMore && provider.hasNext) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    final provider = context.read<UserProvider>();

    if (provider.isFetchingMore || !provider.hasNext) {
      debugPrint(
        '⏸️ [MessageAvatarList] LoadMore skipped | '
        'isFetchingMore: ${provider.isFetchingMore} | '
        'hasNext: ${provider.hasNext}',
      );
      return;
    }

    try {
      debugPrint('🚀 [MessageAvatarList] Loading more users...');

      await provider.fetchUsers(loadMore: true);

      debugPrint('✅ [MessageAvatarList] Load more completed');
    } catch (e) {
      debugPrint('💥 [MessageAvatarList] Load more failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _socketService.onlineUsers,
      builder: (context, onlineUsers, _) {
        return Consumer<UserProvider>(
          builder: (context, p, child) {
            debugPrint(
              '🔄 [MessageAvatarList] REBUILD | '
              'users: ${p.users.length} | '
              'loading: ${p.isLoading} | '
              'fetchingMore: ${p.isFetchingMore}',
            );

            // Initial Loading or Refreshing
            if (p.isLoading) {
              debugPrint('⏳ [MessageAvatarList] Showing skeleton loader');

              return const MessageAvatarSkeleton(avatarCount: 6);
            }

            // Empty State
            if (p.users.isEmpty && !p.isLoading) {
              debugPrint('📭 [MessageAvatarList] No users found');

              return const SizedBox(
                height: 90,
                child: Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            // Success State
            return SizedBox(
              height: 90,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,

                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.symmetric(horizontal: 16),

                cacheExtent: 500,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,

                separatorBuilder: (_, _) => const SizedBox(width: 16),

                itemCount: p.users.length + (p.isFetchingMore ? 1 : 0),

                itemBuilder: (context, index) {
                  // Pagination Loader
                  if (index == p.users.length && p.isFetchingMore) {
                    debugPrint(
                      '⏳ [MessageAvatarList] Showing pagination loader',
                    );

                    return const MessageAvatarPaginationSkeleton();
                  }

                  final user = p.users[index];
                  final isOnline = onlineUsers.contains(
                    UserDisplayHelper.getUserIdForUser(user),
                  );

                  return RepaintBoundary(
                    child: MessageAvatar(
                      key: ValueKey(user.userId),
                      name: UserDisplayHelper.getDisplayNameForUserEntity(user),

                      imageUrl:
                          UserDisplayHelper.getProfileImageForUser(user) ?? '',

                      userId: UserDisplayHelper.getUserIdForUser(user),

                      isOnline: isOnline,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
