import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';

class AlsoShareSheet extends StatefulWidget {
  const AlsoShareSheet({super.key});

  @override
  State<AlsoShareSheet> createState() => _AlsoShareSheetState();
}

class _AlsoShareSheetState extends State<AlsoShareSheet> {
  final TextEditingController _searchController = TextEditingController();
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  final Set<String> _selectedUserIds = {};
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

  void _toggleUserSelection(SearchUser user) {
    setState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
      } else {
        _selectedUserIds.add(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildUserList()),
          Padding(padding: const EdgeInsets.all(20), child: _buildDoneButton()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Search users...',
      backgroundColor: const Color(0xFF1E1A2E),
      borderRadius: 25,
      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
      textStyle: const TextStyle(color: Colors.white, fontSize: 16),
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildUserList() {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _UserListTile(
          user: user,
          isSelected: _selectedUserIds.contains(user.id),
          onShareTap: () => _toggleUserSelection(user),
        );
      },
    );
  }

  Widget _buildDoneButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        debugPrint('Sharing with ${_selectedUserIds.length} users');
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF72008D),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Done',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final SearchUser user;
  final bool isSelected;
  final VoidCallback onShareTap;

  const _UserListTile({
    required this.user,
    required this.isSelected,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[600],
            backgroundImage: user.avatar.isNotEmpty
                ? NetworkImage(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onShareTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF9B27AF), Color(0xFF6A0DAD)],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(color: Colors.white38, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                isSelected ? 'Shared' : 'Share',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
