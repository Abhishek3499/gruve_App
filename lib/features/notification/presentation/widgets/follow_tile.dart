import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/shared/widgets/cached_avatar.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:gruve_app/features/message/utils/conversation_utils.dart';

/// Async callback used for the Accept/Reject/Follow-back actions.
/// Throws on failure so the tile can show an error.
typedef FollowRequestAction = Future<void> Function();

class FollowTile extends ConsumerStatefulWidget {
  final String username;
  final String message;
  final String time;
  final String profileImage;
  final String userId;
  final bool isRead;
  final VoidCallback? onTap;

  /// Drives the trailing button: `accept_reject`, `follow_back`,
  /// `requested`, `message`, or null for no button.
  final String? action;
  final FollowRequestAction? onAccept;
  final FollowRequestAction? onReject;
  final FollowRequestAction? onFollowBack;

  const FollowTile({
    super.key,
    required this.username,
    required this.time,
    required this.profileImage,
    required this.userId,
    this.message = '',
    this.isRead = true,
    this.onTap,
    this.action,
    this.onAccept,
    this.onReject,
    this.onFollowBack,
  });

  @override
  ConsumerState<FollowTile> createState() => _FollowTileState();
}

class _FollowTileState extends ConsumerState<FollowTile> {
  bool _isProcessing = false;

  Future<void> _handle(FollowRequestAction? action) async {
    if (action == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleMessageTap(BuildContext context) {
    ConversationUtils.navigateToChat(
      context: context,
      ref: ref,
      receiverId: widget.userId,
      receiverName: widget.username,
      receiverProfileImage: widget.profileImage.isNotEmpty
          ? widget.profileImage
          : null,
      source: 'follow_tile',
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (_isProcessing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    switch (widget.action) {
      case 'accept_reject':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              label: 'Accept',
              color: const Color(0xFFFE24E0),
              onTap: () {
                widget.onTap?.call();
                _handle(widget.onAccept);
              },
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Reject',
              color: Colors.white24,
              borderColor: Colors.white38,
              onTap: () {
                widget.onTap?.call();
                _handle(widget.onReject);
              },
            ),
          ],
        );
      case 'follow_back':
        return _outlinedButton(
          label: 'Subscribe back',
          onPressed: () {
            widget.onTap?.call();
            _handle(widget.onFollowBack);
          },
        );
      case 'requested':
        return _outlinedButton(
          label: 'Requested',
          onPressed: null,
          textColor: Colors.white70,
        );
      case 'message':
        return _outlinedButton(
          label: 'Message',
          onPressed: () {
            widget.onTap?.call();
            _handleMessageTap(context);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _outlinedButton({
    required String label,
    required VoidCallback? onPressed,
    Color textColor = Colors.white,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(76, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: const BorderSide(color: Colors.white38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMessage = widget.message.isNotEmpty
        ? widget.message
        : "${widget.username} started following you.";

    return InkWell(
      onTap: widget.onTap,
      splashColor: Colors.white12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 24, 8),
        child: Row(
          children: [
            // Unread dot indicator
            if (!widget.isRead)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFC06CFF),
                  shape: BoxShape.circle,
                ),
              ),
            GestureDetector(
              onTap: () {
                if (widget.userId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        profileUserId: widget.userId,
                        userName: widget.username,
                        profileImageUrl: widget.profileImage.isNotEmpty
                            ? widget.profileImage
                            : null,
                      ),
                    ),
                  );
                }
              },
              child: CachedAvatar(
                imageUrl: widget.profileImage,
                username: widget.username,
                radius: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isRead
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white,
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: widget.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.time,
                    style: TextStyle(
                      color: widget.isRead ? Colors.white60 : Colors.white70,
                      fontSize: 11,
                      fontWeight: widget.isRead
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildTrailing(context),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
