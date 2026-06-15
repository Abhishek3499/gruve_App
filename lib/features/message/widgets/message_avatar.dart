import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/conversation_controller.dart';
import '../providers/message_provider.dart';
import '../screen/chat_screen.dart';
import '../../../core/widgets/optimized/optimized_image.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    this.isOnline = false,
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
              OptimizedAvatar(
                imageUrl: imageUrl,
                name: name,
                radius: 30,
              ),

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

  Future<void> _handleTap(BuildContext context) async {
    AppLogger.d('👆 [MessageAvatar] 🎯 Avatar clicked - userId: $userId, name: $name');
    AppLogger.d('🖼️ [MessageAvatar] 📸 Profile image: ${imageUrl.isNotEmpty ? imageUrl : "none"}');
    AppLogger.d('🟢 [MessageAvatar] 📡 Online status: $isOnline');

    final messageProvider = context.read<MessageProvider>();
    final conversationController = context.read<ConversationController>();

    AppLogger.d('🔍 [MessageAvatar] 🔎 Checking for existing conversation with user: $userId');
    AppLogger.d('📊 [MessageAvatar] 💬 Total conversations in provider: ${messageProvider.conversationCount}');
    
    // Check if conversation exists
    final existingConversation = messageProvider.getConversationByUserId(userId);

    if (existingConversation != null) {
      AppLogger.d('✅ [MessageAvatar] 🎉 Existing conversation found!');
      AppLogger.d('💬 [MessageAvatar] 🆔 Conversation ID: ${existingConversation.id}');
      AppLogger.d('👤 [MessageAvatar] 👥 Other user: ${existingConversation.otherUser.name}');
      AppLogger.d('📨 [MessageAvatar] 💭 Last message: ${existingConversation.lastMessage.content}');
      AppLogger.d('🔔 [MessageAvatar] 📬 Unread count: ${existingConversation.unreadCount}');
      AppLogger.d('🧭 [MessageAvatar] 🚀 Navigating to existing chat screen...');
      
      if (!context.mounted) {
        AppLogger.d('⚠️ [MessageAvatar] ❌ Context unmounted, aborting navigation');
        return;
      }
      
      Navigator.push(
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
      AppLogger.d('✅ [MessageAvatar] 🎊 Navigation to existing chat completed');
    } else {
      AppLogger.d('🔍 [MessageAvatar] ❌ No existing conversation found');
      AppLogger.d('🚀 [MessageAvatar] 🆕 Creating new conversation with user: $name ($userId)');
      AppLogger.d('📡 [MessageAvatar] 🌐 Calling API to create conversation...');
      
      if (!context.mounted) {
        AppLogger.d('⚠️ [MessageAvatar] ❌ Context unmounted, aborting');
        return;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
      
      try {
        AppLogger.d('📡 [MessageAvatar] 📶 Creating conversation via API...');
        final conversation = await conversationController.createOrGetConversation(userId);
        
        AppLogger.d('✅ [MessageAvatar] 🎉 Conversation created successfully!');
        AppLogger.d('💬 [MessageAvatar] 🆔 Conversation ID: ${conversation.id}');
        
        // Add to provider
        final existingInProvider = messageProvider.getConversationById(conversation.id);
        if (existingInProvider == null) {
          AppLogger.d('➕ [MessageAvatar] 💾 Adding conversation to MessageProvider');
          messageProvider.addConversation(conversation);
        }
        
        if (!context.mounted) {
          AppLogger.d('⚠️ [MessageAvatar] ❌ Context unmounted after API call');
          return;
        }
        
        // Close loading dialog
        Navigator.pop(context);
        
        AppLogger.d('🧭 [MessageAvatar] 🚀 Navigating to chat screen...');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              receiverId: userId,
              userName: name,
              profileImage: imageUrl.isNotEmpty ? imageUrl : null,
              userOrConversation: conversation,
            ),
          ),
        );
        AppLogger.d('✅ [MessageAvatar] 🎊 Navigation completed successfully');
      } catch (e) {
        AppLogger.d('❌ [MessageAvatar] 💥 Error creating conversation: $e');
        AppLogger.d('🔥 [MessageAvatar] 📋 Error details: ${e.toString()}');
        
        if (!context.mounted) return;
        
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
