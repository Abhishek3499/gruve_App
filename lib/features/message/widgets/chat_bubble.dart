import 'dart:io';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../../../core/assets.dart';
import 'message_popup_menu.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final Function(MessageAction)? onActionSelected;

  const ChatBubble({super.key, required this.message, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showPopupMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: message.isSent
            ? _buildSentBubble(context)
            : _buildReceivedBubble(context),
      ),
    );
  }

  /// ✅ RECEIVED (LEFT — NO PROFILE)
  Widget _buildReceivedBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CustomPaint(
          painter: ChatBubblePainter(isSent: false),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
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

  /// ✅ SENT (RIGHT — WITH PROFILE)
  Widget _buildSentBubble(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomPaint(
          painter: ChatBubblePainter(isSent: true),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
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
        const SizedBox(width: 6),
        CircleAvatar(radius: 18, backgroundImage: AssetImage(AppAssets.user)),
      ],
    );
  }

  Widget _buildStatusRow({required bool isReceived}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isReceived
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        Text(
          "06:14 PM",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.done_all, size: 14, color: Colors.blueAccent),
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

  /// ✅ POPUP MENU
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

/// ✅ BUBBLE SHAPE
class ChatBubblePainter extends CustomPainter {
  final bool isSent;

  ChatBubblePainter({required this.isSent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B008B)
      ..style = PaintingStyle.fill;

    const double r = 16;
    const double tailW = 10;
    const double tailH = 10;
    final double midY = size.height / 2;

    final path = Path();

    if (!isSent) {
      path.moveTo(tailW + r, 0);
      path.lineTo(size.width - r, 0);
      path.quadraticBezierTo(size.width, 0, size.width, r);
      path.lineTo(size.width, size.height - r);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - r,
        size.height,
      );
      path.lineTo(tailW + r, size.height);
      path.quadraticBezierTo(tailW, size.height, tailW, size.height - r);
      path.lineTo(tailW, midY + tailH);
      path.lineTo(0, midY);
      path.lineTo(tailW, midY - tailH);
      path.lineTo(tailW, r);
      path.quadraticBezierTo(tailW, 0, tailW + r, 0);
    } else {
      final double rx = size.width - tailW;
      path.moveTo(r, 0);
      path.lineTo(rx - r, 0);
      path.quadraticBezierTo(rx, 0, rx, r);
      path.lineTo(rx, midY - tailH);
      path.lineTo(size.width, midY);
      path.lineTo(rx, midY + tailH);
      path.lineTo(rx, size.height - r);
      path.quadraticBezierTo(rx, size.height, rx - r, size.height);
      path.lineTo(r, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - r);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChatBubblePainter oldDelegate) =>
      oldDelegate.isSent != isSent;
}
