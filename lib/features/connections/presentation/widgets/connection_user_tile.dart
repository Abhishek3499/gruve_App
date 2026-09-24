import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/connections/data/datasource/connections_service.dart';
import 'package:gruve_app/features/connections/domain/entities/connection_user_model.dart';
import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/message/utils/conversation_utils.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:gruve_app/shared/widgets/cached_avatar.dart';

class ConnectionUserTile extends ConsumerWidget {
  final ConnectionUser user;

  /// Which list this row came from. Each list only tells you the direction
  /// that isn't already implied by list membership:
  /// - [ConnectionType.subscribers]: these users already subscribe to the
  ///   profile being viewed, so `user.isSubscribed` means "viewer subscribes
  ///   to them".
  /// - [ConnectionType.subscribed]: the viewer already subscribes to these
  ///   users, so `user.isSubscribed` means "they subscribe back to viewer".
  final ConnectionType listType;

  const ConnectionUserTile({
    super.key,
    required this.user,
    required this.listType,
  });

  void _openProfile(BuildContext context) {
    if (user.userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          profileUserId: user.userId,
          userName: user.username,
          profileImageUrl: user.profilePicture.isNotEmpty
              ? user.profilePicture
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf =
        user.userId.isNotEmpty &&
        user.userId == AuthStateManager().currentUserId;
    final subscribeController = ref.read(subscribeNotifierProvider);

    // The direction implied by list membership is always true; the API flag
    // carries the other, non-obvious direction.
    final viewerSubscribesToThemSeed = listType == ConnectionType.subscribed
        ? true
        : user.isSubscribed;
    final theyFollowBack = listType == ConnectionType.subscribers
        ? true
        : user.isSubscribed;

    return InkWell(
      onTap: () => _openProfile(context),
      splashColor: Colors.white12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            CachedAvatar(
              imageUrl: user.profilePicture,
              username: user.username.isNotEmpty
                  ? user.username
                  : user.fullName,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isSelf) ...[
              const SizedBox(width: 12),
              _ConnectionActionButton(
                userId: user.userId,
                username: user.username,
                profilePicture: user.profilePicture,
                subscribeController: subscribeController,
                initialIsSubscribed: viewerSubscribesToThemSeed,
                theyFollowBack: theyFollowBack,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionActionButton extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final String profilePicture;
  final SubscribeNotifier subscribeController;
  final bool initialIsSubscribed;
  final bool theyFollowBack;

  const _ConnectionActionButton({
    required this.userId,
    required this.username,
    required this.profilePicture,
    required this.subscribeController,
    required this.initialIsSubscribed,
    required this.theyFollowBack,
  });

  @override
  ConsumerState<_ConnectionActionButton> createState() =>
      _ConnectionActionButtonState();
}

class _ConnectionActionButtonState
    extends ConsumerState<_ConnectionActionButton> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.subscribeController.getUserSubscribeModel(widget.userId) ==
        null) {
      widget.subscribeController.addOrUpdateUser(
        SubscribeModel(
          userId: widget.userId,
          username: widget.username,
          isSubscribed: widget.initialIsSubscribed,
          subscribedAt: widget.initialIsSubscribed ? DateTime.now() : null,
        ),
      );
    }
  }

  Future<void> _toggleSubscription() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.subscribeController.toggleSubscription(widget.userId);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openMessage() {
    ConversationUtils.navigateToChat(
      context: context,
      ref: ref,
      receiverId: widget.userId,
      receiverName: widget.username,
      receiverProfileImage: widget.profilePicture.isNotEmpty
          ? widget.profilePicture
          : null,
      source: 'connections_screen',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.subscribeController,
      builder: (context, _) {
        final viewerSubscribed = widget.subscribeController.isUserSubscribed(
          widget.userId,
        );
        final isMutual = viewerSubscribed && widget.theyFollowBack;

        if (isMutual) {
          return _buildButton(
            label: 'Message',
            filled: false,
            onPressed: _openMessage,
          );
        }

        return Opacity(
          opacity: _isProcessing ? 0.6 : 1.0,
          child: _buildButton(
            label: viewerSubscribed ? 'Subscribed' : 'Subscribe',
            filled: !viewerSubscribed,
            onPressed: _toggleSubscription,
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String label,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: filled ? const Color(0xFFFE24E0) : Colors.transparent,
        side: BorderSide(
          color: filled
              ? const Color(0xFFFE24E0)
              : const Color.fromARGB(255, 227, 224, 224),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
