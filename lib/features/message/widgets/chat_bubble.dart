import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import '../models/message_model.dart';
import '../utils/shared_post_message_parser.dart';
import 'message_popup_menu.dart';
import 'shared_post_preview_card.dart';
import 'voice_message_player.dart';
import '../screen/fullscreen_media_viewer.dart';

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
    HapticFeedback.vibrate();
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
    if (message.isAudio) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SenderAvatar(avatarUrl: message.senderAvatar, name: message.senderName),
          const SizedBox(width: 8),
          _buildAudioBubble(context, isSent: false),
        ],
      );
    }

    if (message.hasMedia && !message.isSharedPost) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SenderAvatar(avatarUrl: message.senderAvatar, name: message.senderName),
          const SizedBox(width: 8),
          _buildMediaBubble(context, isSent: false),
        ],
      );
    }

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
              maxWidth: message.isSharedPost
                  ? MediaQuery.of(context).size.width * 0.72
                  : MediaQuery.of(context).size.width * 0.68,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.hasReply) _buildReplyQuote(),
                if (message.hasImage) _buildImageContent(context),
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
    if (message.isAudio) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAudioBubble(context, isSent: true),
        ],
      );
    }

    if (message.hasMedia && !message.isSharedPost) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMediaBubble(context, isSent: true),
        ],
      );
    }

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
              maxWidth: message.isSharedPost
                  ? MediaQuery.of(context).size.width * 0.72
                  : MediaQuery.of(context).size.width * 0.68,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.hasReply) _buildReplyQuote(),
                if (message.hasImage) _buildImageContent(context),
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

  Widget _buildAudioBubble(BuildContext context, {required bool isSent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaWidth = screenWidth * 0.72;

    return CustomPaint(
      painter: ChatBubblePainter(
        isSent: isSent,
        bubbleColor: isSent ? const Color(0xFF4A148C) : const Color(0xFF6A008A),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: mediaWidth + 12),
        padding: EdgeInsets.fromLTRB(
          isSent ? 15 : 20,
          10,
          isSent ? 20 : 15,
          10,
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.hasReply) _buildReplyQuote(),
            VoiceMessagePlayer(
              audioUrl: message.imagePath ?? '',
              isSent: isSent,
            ),
            const SizedBox(height: 4),
            _buildStatusRow(isReceived: !isSent),
          ],
        ),
      ),
    );
  }

  bool _hasVisibleCaption() {
    if (_shouldHideMediaCaption()) return false;
    return message.text.trim().isNotEmpty;
  }

  /// WhatsApp-style media bubble: large image with optional caption below.
  Widget _buildMediaBubble(BuildContext context, {required bool isSent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaWidth = screenWidth * 0.72;
    final mediaHeight = mediaWidth * 0.75;
    final hasCaption = _hasVisibleCaption();

    return CustomPaint(
      painter: ChatBubblePainter(
        isSent: isSent,
        bubbleColor: isSent ? const Color(0xFF4A148C) : const Color(0xFF6A008A),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: mediaWidth + 12),
        padding: EdgeInsets.fromLTRB(
          isSent ? 4 : 8,
          4,
          isSent ? 8 : 4,
          4,
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.hasReply) _buildReplyQuote(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => _openFullscreenMedia(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: mediaWidth,
                      height: mediaHeight,
                      child: _buildMediaWidget(mediaWidth, mediaHeight),
                    ),
                  ),
                ),
                if (!hasCaption)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: _buildMediaTimestampOverlay(isReceived: !isSent),
                  ),
              ],
            ),
            if (hasCaption) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2, left: 8),
                child: _buildStatusRow(isReceived: !isSent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTimestampOverlay({required bool isReceived}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildStatusRow(isReceived: isReceived),
    );
  }

  Widget _buildMediaWidget(double width, double height) {
    final path = message.imagePath!.trim();

    if (message.isVideo) {
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          VideoThumbnailWidget(
            videoPath: path,
            width: width,
            height: height,
          ),
          const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 48,
          ),
        ],
      );
    }

    if (message.isLocalMedia) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _mediaError(width, height),
      );
    }

    return CachedNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      width: width,
      height: height,
      placeholder: (_, _) => _mediaPlaceholder(width, height),
      errorWidget: (_, _, _) => _mediaError(width, height),
    );
  }

  Widget _mediaPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.white12,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
      ),
    );
  }

  Widget _mediaError(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.white12,
      child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isSharedPost) {
      final companion = message.sharedPostCompanionText;
      return Column(
        crossAxisAlignment:
            message.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (companion != null) ...[
            Text(
              companion,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
          SharedPostPreviewCard(
            key: ValueKey(
              'shared_post_${message.id}_${message.sharedPostId}',
            ),
            postId: message.sharedPostId!,
            isSent: message.isSent,
            initialPreviewUrl: message.sharedPostPreviewUrl,
            isTaggedPost: SharedPostMessageParser.isTaggedPostMessage(
              message.text,
            ),
            preloadedPost: message.sharedPost,
            senderDisplayName: message.senderName,
            senderAvatar: message.senderAvatar,
            senderUserId: message.senderId,
          ),
        ],
      );
    }

    if (_shouldHideMediaCaption()) {
      return const SizedBox.shrink();
    }

    return Text(
      message.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  bool _shouldHideMediaCaption() {
    if (!message.hasMedia) return message.text.trim().isEmpty;
    if (message.text.trim().isEmpty) return true;
    final label = message.text.trim().toLowerCase();
    return label == 'photo' || label == 'video' || label == 'image';
  }

  Widget _buildReplyQuote() {
    final preview = message.effectiveReplyPreview;
    if (preview == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: message.isSent
                ? const Color(0xFFCE93D8)
                : const Color(0xFFE1BEE7),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.senderName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            preview.displayText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({required bool isReceived}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited) ...[
          Text(
            'edited',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
        ],
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

  Widget _buildImageContent(BuildContext context) {
    // Legacy text-bubble media fallback (shared posts use separate layout).
    final screenWidth = MediaQuery.of(context).size.width;
    final mediaWidth = screenWidth * 0.68;
    final mediaHeight = mediaWidth * 0.72;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _openFullscreenMedia(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: mediaWidth,
            height: mediaHeight,
            child: _buildMediaWidget(mediaWidth, mediaHeight),
          ),
        ),
      ),
    );
  }

  void _openFullscreenMedia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenMediaViewer(
          mediaPath: message.imagePath ?? '',
          isVideo: message.isVideo,
        ),
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

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double width;
  final double height;

  const VideoThumbnailWidget({
    super.key,
    required this.videoPath,
    required this.width,
    required this.height,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _initController();
    }
  }

  void _initController() async {
    final path = widget.videoPath.trim();
    if (path.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final isLocal = !path.startsWith('http://') && !path.startsWith('https://');
    try {
      if (isLocal) {
        _controller = VideoPlayerController.file(File(path));
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(path));
      }

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      AppLogger.d('💥 [VideoThumbnailWidget] Error initializing video thumbnail: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.white12,
        child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.white12,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width > 0 ? _controller!.value.size.width : widget.width,
          height: _controller!.value.size.height > 0 ? _controller!.value.size.height : widget.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
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
