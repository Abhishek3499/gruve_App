import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/message/presentation/provider/user_provider.dart';
import 'package:gruve_app/features/search/data/user_search/user_search_service.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';

import 'share_user_item.dart';

class ShareUserGrid extends StatefulWidget {
  final Set<SearchUser> selectedUsers;
  final ValueChanged<SearchUser> onUserToggle;

  const ShareUserGrid({
    super.key,
    required this.selectedUsers,
    required this.onUserToggle,
  });

  @override
  State<ShareUserGrid> createState() => _ShareUserGridState();
}

class _ShareUserGridState extends State<ShareUserGrid> {
  final TextEditingController _searchController = TextEditingController();
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  List<SearchUser> _users = [];
  bool _isSearching = false;
  String? _searchError;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSearch.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_searchController.text.trim().isNotEmpty) return;

    final provider = context.read<UserProvider>();
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 100.0;

    if (maxScroll - currentScroll <= delta) {
      if (!provider.isFetchingMore && provider.hasNext) {
        provider.fetchUsers(loadMore: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchError = null;
      _isSearching = query.trim().isNotEmpty;
      if (query.trim().isEmpty) {
        _users = [];
      }
    });

    if (query.trim().isEmpty) {
      _userSearch.clear();
      return;
    }

    _userSearch.search(
      query,
      onResults: (users) {
        if (!mounted) return;
        setState(() {
          _users = users;
          _isSearching = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _users = [];
          _isSearching = false;
          _searchError = 'Unable to search users right now';
        });
      },
    );
  }

  void _onUserTap(SearchUser user) {
    widget.onUserToggle(user);
  }

  bool _isUserSelected(SearchUser user) {
    return widget.selectedUsers.any((u) => u.id == user.id);
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
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD42BC2)),
      );
    }

    if (_searchError != null) {
      return Center(
        child: Text(
          _searchError!,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    // 1. Search Results Mode
    if (_searchController.text.trim().isNotEmpty) {
      if (_users.isEmpty) {
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
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ShareUserItem(
            user: user,
            isSelected: _isUserSelected(user),
            onTap: () => _onUserTap(user),
          );
        },
      );
    }

    // 2. General Users List Mode (Initial/Cached List)
    final provider = context.watch<UserProvider>();
    
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD42BC2)),
      );
    }

    if (provider.errorMessage != null && provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.fetchUsers(),
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

    final generalUsers = provider.users;
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
      itemCount: generalUsers.length + (provider.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == generalUsers.length && provider.isFetchingMore) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD42BC2)),
          );
        }

        final user = generalUsers[index];
        final searchUser = SearchUser(
          id: user.userId,
          name: user.fullName,
          username: user.username,
          avatar: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
              ? user.profilePicture!
              : '',
        );

        return ShareUserItem(
          user: searchUser,
          isSelected: _isUserSelected(searchUser),
          onTap: () => _onUserTap(searchUser),
        );
      },
    );
  }
}
