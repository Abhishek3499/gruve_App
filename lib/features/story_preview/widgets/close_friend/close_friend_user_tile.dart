import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/models/close_frind_user_model.dart';

class CloseFriendUserTile extends StatelessWidget {
  final CloseFrindUserModel user;
  final VoidCallback onTap;

  const CloseFriendUserTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 24,
        backgroundImage: AssetImage(AppAssets.frame1),
      ),

      title: Text(user.name, style: const TextStyle(color: Colors.white)),

      subtitle: Text(
        user.handle,
        style: const TextStyle(color: Colors.white70),
      ),

      trailing: GestureDetector(
        onTap: onTap,
        child: Icon(
          user.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: Color(0xFF7F56D9),
        ),
      ),
    );
  }
}
