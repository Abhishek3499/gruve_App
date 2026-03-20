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
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment: pinnedMessage.isSent
            ? MainAxisAlignment
                  .end // sent message → right side
            : MainAxisAlignment.start, // received message → left side
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: pinnedMessage.isSent ? 0 : 52, // avatar width offset
              right: pinnedMessage.isSent ? 52 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pin icon
                Image.asset(
                  'assets/icons/pin.png', // apna pin asset use karo
                  width: 14,
                  height: 14,
                  color: Colors.white,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.push_pin,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 5),
                // "skyler. Pinned" text
                Text(
                  '$username. Pinned',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
