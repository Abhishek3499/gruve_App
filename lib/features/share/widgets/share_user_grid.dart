import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';

import 'share_user_item.dart';

class ShareUserGrid extends StatefulWidget {
  const ShareUserGrid({super.key});

  @override
  State<ShareUserGrid> createState() => _ShareUserGridState();
}

class _ShareUserGridState extends State<ShareUserGrid> {
  final TextEditingController _searchController = TextEditingController();
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  List<SearchUser> _users = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _userSearch.dispose();
    super.dispose();
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
    // Handle user selection for sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared with ${user.username}'),
        backgroundColor: const Color(0xFF7A1FA2),
        duration: const Duration(seconds: 2),
      ),
    );
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

    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Search users to share',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return GridView.builder(
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
        return ShareUserItem(user: user, onTap: () => _onUserTap(user));
      },
    );
  }
}
