import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';

import 'close_friend_user_tile.dart';

class CloseFriendUserList extends StatelessWidget {
  final List<SearchUser> users;
  final Set<String> selectedUserIds;
  final bool isSearching;
  final String? errorMessage;
  final bool hasQuery;
  final ValueChanged<SearchUser> onToggle;

  const CloseFriendUserList({
    super.key,
    required this.users,
    required this.selectedUserIds,
    required this.isSearching,
    required this.hasQuery,
    required this.onToggle,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD42BC2)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    if (!hasQuery) {
      return const Center(
        child: Text(
          'Search to add close friends',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    final selected = users
        .where((user) => selectedUserIds.contains(user.id))
        .toList();
    final suggested = users
        .where((user) => !selectedUserIds.contains(user.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (selected.isNotEmpty)
          ...selected.map(
            (user) => CloseFriendUserTile(
              user: user,
              isSelected: true,
              onTap: () => onToggle(user),
            ),
          ),
        if (selected.isNotEmpty) const SizedBox(height: 20),
        const Text(
          'Suggest',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...suggested.map(
          (user) => CloseFriendUserTile(
            user: user,
            isSelected: false,
            onTap: () => onToggle(user),
          ),
        ),
      ],
    );
  }
}
