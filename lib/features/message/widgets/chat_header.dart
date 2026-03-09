import 'package:flutter/material.dart';
import '../../../core/assets.dart';
import '../models/message_model.dart';

class ChatHeader extends StatelessWidget {
  final ChatUser user;
  final VoidCallback onBack;

  const ChatHeader({super.key, required this.user, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(),
      child: Row(
        children: [
          /// Back Button
          GestureDetector(
            onTap: onBack,
            child: Image.asset(
              AppAssets.back,
              width: 24,
              height: 24,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          /// User Avatar
          CircleAvatar(radius: 20, backgroundImage: AssetImage(user.avatar)),

          const SizedBox(width: 12),

          /// User Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          /// More Options
          IconButton(
            onPressed: () {
              // TODO: Implement more options
            },
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
