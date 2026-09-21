import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/message/presentation/notifiers/user_notifier.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/features/search/presentation/widgets/search_bar.dart';
import 'package:gruve_app/features/share/presentation/controller/post_share_provider.dart';

import 'package:gruve_app/features/share/presentation/widgets/share_user_item.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class ShareUserGrid extends ConsumerStatefulWidget {
  const ShareUserGrid({super.key});

  @override
  ConsumerState<ShareUserGrid> createState() => _ShareUserGridState();
}

class _ShareUserGridState extends ConsumerState<ShareUserGrid> {
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userNotifierProvider.notifier).fetchUsers(reason: 'initial');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_searchController.text.trim().isNotEmpty) return;

    final userState = ref.read(userNotifierProvider);
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: userState.isLoading || userState.isFetchingMore,
      hasMore: userState.hasNext,
    )) {
      return;
    }

    ref
        .read(userNotifierProvider.notifier)
        .fetchUsers(loadMore: true, reason: 'scroll');
  }

  void _onSearchChanged(String query) {
    ref.read(postShareNotifierProvider.notifier).updateSearchQuery(query);
  }

  void _onUserTap(SearchUser user) {
    ref.read(postShareNotifierProvider.notifier).toggleUser(user);
  }

  bool _isUserSelected(PostShareState shareState, SearchUser user) {
    return shareState.selectedUsers.any((u) => u.id == user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: ' Search',
            backgroundColor: const Color.fromARGB(77, 23, 22, 22),
            borderGradient: null,
            border: Border.all(
              color: const Color.fromARGB(248, 79, 2, 98),
              width: 1,
            ),
            borderWidth: 0,
            borderRadius: 15,
            height: 48,
            prefixIcon: null,
            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
            hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        const SizedBox(height: 16),

        // Users grid
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    final shareState = ref.watch(postShareNotifierProvider);
    final isSearching = shareState.isSearching;
    final searchError = shareState.searchError;
    final searchResults = shareState.searchResults;

    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.vibrantMagenta),
      );
    }

    if (searchError != null) {
      return Center(
        child: Text(
          searchError,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    // 1. Search Results Mode
    if (_searchController.text.trim().isNotEmpty) {
      if (searchResults.isEmpty) {
        return const Center(
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        );
      }

      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final user = searchResults[index];
          return ShareUserItem(
            user: user,
            isSelected: _isUserSelected(shareState, user),
            onTap: () => _onUserTap(user),
          );
        },
      );
    }

    // 2. General Users List Mode (Initial/Cached List)
    final userState = ref.watch(userNotifierProvider);

    if (userState.isLoading && userState.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.vibrantMagenta),
      );
    }

    if (userState.errorMessage != null && userState.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userState.errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(userNotifierProvider.notifier).fetchUsers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 120, 2, 99),
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final generalUsers = userState.users;
    if (generalUsers.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: generalUsers.length + (userState.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == generalUsers.length && userState.isFetchingMore) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.vibrantMagenta),
          );
        }

        final user = generalUsers[index];
        final searchUser = SearchUser(
          id: user.userId,
          name: user.fullName,
          username: user.username,
          avatar:
              (user.profilePicture != null && user.profilePicture!.isNotEmpty)
              ? user.profilePicture!
              : '',
        );

        return ShareUserItem(
          user: searchUser,
          isSelected: _isUserSelected(shareState, searchUser),
          onTap: () => _onUserTap(searchUser),
        );
      },
    );
  }
}
