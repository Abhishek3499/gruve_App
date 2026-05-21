import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/conversation_controller.dart';
import '../providers/message_provider.dart';
import '../screen/chat_screen.dart';
import '../../../core/widgets/optimized/optimized_image.dart';

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
    debugPrint('👆 [MessageAvatar] 🎯 Avatar clicked - userId: $userId, name: $name');
    debugPrint('🖼️ [MessageAvatar] 📸 Profile image: ${imageUrl.isNotEmpty ? imageUrl : "none"}');
    debugPrint('🟢 [MessageAvatar] 📡 Online status: $isOnline');

    final messageProvider = context.read<MessageProvider>();
    final conversationController = context.read<ConversationController>();

    debugPrint('🔍 [MessageAvatar] 🔎 Checking for existing conversation with user: $userId');
    debugPrint('📊 [MessageAvatar] 💬 Total conversations in provider: ${messageProvider.conversationCount}');
    
    // Check if conversation exists
    final existingConversation = messageProvider.getConversationByUserId(userId);

    if (existingConversation != null) {
      debugPrint('✅ [MessageAvatar] 🎉 Existing conversation found!');
      debugPrint('💬 [MessageAvatar] 🆔 Conversation ID: ${existingConversation.id}');
      debugPrint('👤 [MessageAvatar] 👥 Other user: ${existingConversation.otherUser.name}');
      debugPrint('📨 [MessageAvatar] 💭 Last message: ${existingConversation.lastMessage.content}');
      debugPrint('🔔 [MessageAvatar] 📬 Unread count: ${existingConversation.unreadCount}');
      debugPrint('🧭 [MessageAvatar] 🚀 Navigating to existing chat screen...');
      
      if (!context.mounted) {
        debugPrint('⚠️ [MessageAvatar] ❌ Context unmounted, aborting navigation');
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
      debugPrint('✅ [MessageAvatar] 🎊 Navigation to existing chat completed');
    } else {
      debugPrint('🔍 [MessageAvatar] ❌ No existing conversation found');
      debugPrint('🚀 [MessageAvatar] 🆕 Creating new conversation with user: $name ($userId)');
      debugPrint('📡 [MessageAvatar] 🌐 Calling API to create conversation...');
      
      if (!context.mounted) {
        debugPrint('⚠️ [MessageAvatar] ❌ Context unmounted, aborting');
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
        debugPrint('📡 [MessageAvatar] 📶 Creating conversation via API...');
        final conversation = await conversationController.createOrGetConversation(userId);
        
        debugPrint('✅ [MessageAvatar] 🎉 Conversation created successfully!');
        debugPrint('💬 [MessageAvatar] 🆔 Conversation ID: ${conversation.id}');
        
        // Add to provider
        final existingInProvider = messageProvider.getConversationById(conversation.id);
        if (existingInProvider == null) {
          debugPrint('➕ [MessageAvatar] 💾 Adding conversation to MessageProvider');
          messageProvider.addConversation(conversation);
        }
        
        if (!context.mounted) {
          debugPrint('⚠️ [MessageAvatar] ❌ Context unmounted after API call');
          return;
        }
        
        // Close loading dialog
        Navigator.pop(context);
        
        debugPrint('🧭 [MessageAvatar] 🚀 Navigating to chat screen...');
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
        debugPrint('✅ [MessageAvatar] 🎊 Navigation completed successfully');
      } catch (e) {
        debugPrint('❌ [MessageAvatar] 💥 Error creating conversation: $e');
        debugPrint('🔥 [MessageAvatar] 📋 Error details: ${e.toString()}');
        
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
