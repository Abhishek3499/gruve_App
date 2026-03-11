import 'package:flutter/material.dart';
import '../models/reply_message_model.dart';

class ReplyPreviewBar extends StatelessWidget {
  final ReplyMessageModel replyMessage;
  final VoidCallback onClose;

  const ReplyPreviewBar({
    super.key,
    required this.replyMessage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Left purple indicator
          Container(
            width: 4,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF72008D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Reply label
                Text(
                  "Replying to ${replyMessage.username}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                /// Message preview
                Text(
                  replyMessage.displayText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          /// Close button
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
