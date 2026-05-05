import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';
import 'package:gruve_app/core/assets.dart';

class CloseFriendUserTile extends StatelessWidget {
  final SearchUser user;
  final bool isSelected;
  final VoidCallback onTap;

  const CloseFriendUserTile({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.avatar.isNotEmpty
            ? NetworkImage(user.avatar)
            : const AssetImage(AppAssets.frame1) as ImageProvider,
      ),

      title: Text(user.name, style: const TextStyle(color: Colors.white)),

      subtitle: Text(
        '@${user.username}',
        style: const TextStyle(color: Colors.white70),
      ),

      trailing: GestureDetector(
        onTap: onTap,
        child: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: const Color(0xFF7F56D9),
        ),
      ),
    );
  }
}
