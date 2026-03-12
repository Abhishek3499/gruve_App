import 'package:flutter/material.dart';
import '../../../core/assets.dart';
import '../models/message_model.dart';
import 'chat_header_menu.dart';

class ChatHeader extends StatelessWidget {
  final ChatUser user;
  final VoidCallback onBack;

  const ChatHeader({super.key, required this.user, required this.onBack});

  void showChatHeaderMenu(BuildContext context) {
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          overlayEntry?.remove();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full screen transparent barrier
              Positioned.fill(
                child: Container(color: Colors.transparent),
              ),
              // Menu positioned at top right
              Positioned(
                top: 60, // Position below header
                right: 16, // Align to right side
                child: GestureDetector(
                  onTap: () {}, // Prevent tap through to menu
                  child: ChatHeaderMenu(
                    onClose: () => overlayEntry?.remove(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

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
            onPressed: () => showChatHeaderMenu(context),
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
