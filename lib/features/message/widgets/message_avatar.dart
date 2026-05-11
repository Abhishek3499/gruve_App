import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/conversation_utils.dart';
import '../screen/chat_screen.dart';

class MessageAvatar extends StatelessWidget {
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
    this.isOnline = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[600],
                backgroundImage: imageUrl.isNotEmpty 
                    ? CachedNetworkImageProvider(imageUrl) 
                    : null,
                child: imageUrl.isEmpty 
                    ? const Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
              ),

              /// Online green dot
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

  void _handleTap(BuildContext context) {
    debugPrint('👤 [MessageAvatar] Navigating to chat - userId: $userId, name: $name');
    
    // Create user data object for ChatScreen navigation
    final userData = {
      'id': userId,
      'name': name,
      'profileImage': imageUrl.isNotEmpty ? imageUrl : null,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userOrConversation: userData,
        ),
      ),
    );
  }
}
