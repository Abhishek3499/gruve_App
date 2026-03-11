import 'package:flutter/material.dart';
import '../models/message_model.dart';

class PinnedMessageBanner extends StatelessWidget {
  final MessageModel pinnedMessage;
  final String username;

  const PinnedMessageBanner({
    super.key,
    required this.pinnedMessage,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF311B36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF72008D), width: 1),
      ),
      child: Row(
        children: [
          // Pin icon
          const Icon(
            Icons.push_pin,
            color: Color(0xFF72008D),
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          // Pinned message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pinned label
                const Text(
                  'Pinned message',
                  style: TextStyle(
                    color: Color(0xFF72008D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Username and preview
                Text(
                  '$username: ${pinnedMessage.text.isNotEmpty ? pinnedMessage.text : "Image"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
