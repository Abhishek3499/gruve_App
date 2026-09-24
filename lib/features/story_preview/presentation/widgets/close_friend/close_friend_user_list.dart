import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';

import 'package:gruve_app/features/story_preview/presentation/widgets/close_friend/close_friend_user_tile.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class CloseFriendUserList extends StatelessWidget {
  final List<SearchUser> users;
  final Set<String> selectedUserIds;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final ValueChanged<SearchUser> onToggle;
  final ScrollController? scrollController;

  const CloseFriendUserList({
    super.key,
    required this.users,
    required this.selectedUserIds,
    required this.isLoading,
    required this.onToggle,
    this.isLoadingMore = false,
    this.errorMessage,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.vibrantMagenta),
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

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No friends found',
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
      controller: scrollController,
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
        if (suggested.isNotEmpty) ...[
          const Text(
            'Suggest',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 10),
        ],
        ...suggested.map(
          (user) => CloseFriendUserTile(
            user: user,
            isSelected: false,
            onTap: () => onToggle(user),
          ),
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.vibrantMagenta,
              ),
            ),
          ),
      ],
    );
  }
}
