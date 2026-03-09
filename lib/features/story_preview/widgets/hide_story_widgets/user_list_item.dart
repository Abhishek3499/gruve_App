import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class UserListItem extends StatelessWidget {
  final String username;
  final String handle;
  final bool isSelected;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.username,
    required this.handle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage(AppAssets.saved3),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  handle,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
