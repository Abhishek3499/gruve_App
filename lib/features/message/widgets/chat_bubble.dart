import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/message_model.dart';
import 'message_popup_menu.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/profile/screens/post_detail/profile_post_detail_screen.dart';

class ChatBubble extends MessageBubble {
  const ChatBubble({
    super.key,
    required super.message,
    super.onActionSelected,
    super.onLongPress,
  });
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final Function(MessageAction)? onActionSelected;

  // ── New: long press callback with position + size ──
  final void Function(Offset globalPosition, Size size)? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onActionSelected,
    this.onLongPress,
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
        _SenderAvatar(avatarUrl: message.senderAvatar, name: message.senderName),
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
                _buildMessageContent(context),
                const SizedBox(height: 4),
                _buildStatusRow(isReceived: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ SENT (RIGHT - NO AVATAR)
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
                _buildMessageContent(context),
                const SizedBox(height: 4),
                _buildStatusRow(isReceived: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final postTagRegex = RegExp(r'View post:\s*(pst_[a-zA-Z0-9_\-]+)');
    final match = postTagRegex.firstMatch(message.text);
    if (match != null) {
      final postId = match.group(1);
      if (postId != null) {
        return Column(
          crossAxisAlignment: message.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildViewPostButton(context, postId),
          ],
        );
      }
    }
    return Text(
      message.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Widget _buildViewPostButton(BuildContext context, String postId) {
    return InkWell(
      onTap: () => _handleViewPostTap(context, postId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_fill_outlined,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              "View Post",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleViewPostTap(BuildContext context, String postId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final postService = PostService();
      final post = await postService.fetchPostById(postId);

      if (context.mounted) {
        Navigator.pop(context); // pop loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePostDetailScreen(
              post: post,
              allPosts: [post],
              initialIndex: 0,
              isOwnProfile: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load post: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusRow({required bool isReceived}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        if (!isReceived) ...[
          const SizedBox(width: 4),
          _buildTickIcon(),
        ],
      ],
    );
  }

  Widget _buildTickIcon() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.white.withValues(alpha: 0.5),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withValues(alpha: 0.5),
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF34B7F1), // Sleek WhatsApp double blue tick color
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
    }
  }

  String _formatTime() {
    final localTime = message.timestamp.toLocal();
    final hour = localTime.hour > 12
        ? localTime.hour - 12
        : localTime.hour == 0
            ? 12
            : localTime.hour;
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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

/// Cached avatar with shimmer placeholder and fallback initials.
class _SenderAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;

  const _SenderAvatar({this.avatarUrl, this.name});

  @override
  Widget build(BuildContext context) {
    const double radius = 18;
    const double size = radius * 2;

    final url = (avatarUrl?.trim().isNotEmpty == true) ? avatarUrl! : null;

    if (url == null) return _fallback(size);

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (_, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.white12,
        highlightColor: Colors.white24,
        child: CircleAvatar(radius: radius, backgroundColor: Colors.white12),
      ),
      errorWidget: (_, _, _) => _fallback(size),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: size.toInt() * 2,
      memCacheHeight: size.toInt() * 2,
    );
  }

  Widget _fallback(double size) {
    final initial = (name?.trim().isNotEmpty == true)
        ? name![0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF6A008A),
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
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
