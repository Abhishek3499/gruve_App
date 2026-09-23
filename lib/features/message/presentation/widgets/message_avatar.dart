import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/message/presentation/notifiers/message_notifier.dart';
import 'package:gruve_app/features/message/presentation/screens/chat_screen.dart';
import 'package:gruve_app/shared/widgets/optimized/optimized_image.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class MessageAvatar extends ConsumerWidget {
  final String name;
  final String imageUrl;
  final bool isOnline;
  final String userId;
  final VoidCallback? onTap;

  const MessageAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.userId,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context, ref),
      child: Column(
        children: [
          Stack(
            children: [
              OptimizedAvatar(imageUrl: imageUrl, name: name, radius: 30),

              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    AppLogger.d(
      '[MessageAvatar] Avatar clicked - userId: $userId, name: $name',
    );

    final messageNotifier = ref.read(messageNotifierProvider.notifier);

    // Check if conversation exists
    final existingConversation = messageNotifier.getConversationByUserId(
      userId,
    );

    if (existingConversation != null) {
      AppLogger.d(
        '[MessageAvatar] Existing conversation found: ${existingConversation.id}',
      );

      if (!context.mounted) {
        AppLogger.d('[MessageAvatar] Context unmounted, aborting navigation');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: existingConversation.id,
            receiverId: userId,
            userName: name,
            profileImage: imageUrl.isNotEmpty ? imageUrl : null,
            userOrConversation: existingConversation,
          ),
        ),
      );
    } else {
      AppLogger.d(
        '[MessageAvatar] No existing conversation found, navigating to ChatScreen',
      );

      if (!context.mounted) {
        AppLogger.d('[MessageAvatar] Context unmounted, aborting');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: userId,
            userName: name,
            profileImage: imageUrl.isNotEmpty ? imageUrl : null,
          ),
        ),
      );
    }

    if (context.mounted) {
      AppLogger.d(
        '[MessageAvatar] User returned from ChatScreen - refreshing list',
      );
      unawaited(messageNotifier.fetchConversations(refresh: true));
    }
  }
}
