import 'dart:io';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../../../core/assets.dart';
import 'message_popup_menu.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final Function(MessageAction)? onActionSelected;

  // ── New: long press callback with position + size ──
  final void Function(Offset globalPosition, Size size)? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.onActionSelected,
    this.onLongPress, // pass this from ChatScreen
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) => _handleLongPress(context, details),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: message.isSent
            ? _buildSentBubble(context)
            : _buildReceivedBubble(context),
      ),
    );
  }

  // ── Capture position of the bubble on long press ──
  void _handleLongPress(BuildContext context, LongPressStartDetails details) {
    // Get the RenderBox of this widget to find its global position & size
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final Offset globalPos = box.localToGlobal(Offset.zero);
      final Size size = box.size;

      if (onLongPress != null) {
        // Use new callback — chat_screen will handle popup
        onLongPress!(globalPos, size);
      } else {
        // Fallback: old bottom sheet (in case onLongPress not passed)
        _showPopupMenu(context);
      }
    }
  }

  /// ✅ RECEIVED (LEFT - FIXED WITH AVATAR)
  Widget _buildReceivedBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(radius: 18, backgroundImage: AssetImage(AppAssets.user)),
        const SizedBox(width: 8),
        CustomPaint(
          painter: ChatBubblePainter(
            isSent: false,
            bubbleColor: const Color(0xFF6A008A),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 15, 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.hasImage) _buildImageContent(),
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                _buildStatusRow(isReceived: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ SENT (RIGHT - FIXED)
  Widget _buildSentBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomPaint(
          painter: ChatBubblePainter(
            isSent: true,
            bubbleColor: const Color(0xFF4A148C),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 20, 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.hasImage) _buildImageContent(),
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                _buildStatusRow(isReceived: false),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(radius: 18, backgroundImage: AssetImage(AppAssets.user)),
      ],
    );
  }

  Widget _buildStatusRow({required bool isReceived}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "06:14 PM",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        if (!isReceived) ...[
          const SizedBox(width: 4),
          const Icon(Icons.done_all, size: 14, color: Colors.blueAccent),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(message.imagePath!), fit: BoxFit.cover),
      ),
    );
  }

  // ── Fallback: old bottom sheet (used if onLongPress not passed) ──
  void _showPopupMenu(BuildContext context) async {
    final action = await showModalBottomSheet<MessageAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagePopupMenu(),
    );

    if (action != null && onActionSelected != null) {
      onActionSelected!(action);
    }
  }
}

/// ✅ BUBBLE SHAPE — NO CHANGES
class ChatBubblePainter extends CustomPainter {
  final bool isSent;
  final Color bubbleColor;

  ChatBubblePainter({required this.isSent, required this.bubbleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final path = Path();
    const double radius = 20;

    if (!isSent) {
      path.moveTo(radius + 10, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      );
      path.lineTo(15, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height + 8);
      path.quadraticBezierTo(5, size.height - 5, 10, size.height - 10);
      path.lineTo(10, radius);
      path.quadraticBezierTo(10, 0, radius + 10, 0);
    } else {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius - 10, 0);
      path.quadraticBezierTo(size.width - 10, 0, size.width - 10, radius);
      path.lineTo(size.width - 10, size.height - 10);
      path.quadraticBezierTo(
        size.width - 10,
        size.height - 5,
        size.width,
        size.height + 8,
      );
      path.quadraticBezierTo(
        size.width - 5,
        size.height,
        size.width - 15,
        size.height,
      );
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter oldDelegate) =>
      oldDelegate.isSent != isSent || oldDelegate.bubbleColor != bubbleColor;
}
