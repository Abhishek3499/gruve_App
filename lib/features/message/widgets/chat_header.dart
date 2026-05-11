import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/assets.dart';
import '../models/conversation_model.dart';
import 'chat_header_menu.dart';
import '../../../features/user_profiles/widgets/screens/user_profile_screen2.dart';

class ChatHeader extends StatelessWidget {
  // Support both old ChatUser and new ConversationModel for backward compatibility
  final dynamic userOrConversation;
  final VoidCallback onBack;

  const ChatHeader({
    super.key,
    required this.userOrConversation,
    required this.onBack,
  });

  // Helper getters for backward compatibility
  bool get _isConversationModel => userOrConversation is ConversationModel;
  String get _userName {
    if (_isConversationModel) {
      return (userOrConversation as ConversationModel).otherUserName;
    }
    return (userOrConversation as dynamic).name ?? 'Unknown';
  }

  String get _userId {
    if (_isConversationModel) {
      return (userOrConversation as ConversationModel).otherUser.id;
    }
    return (userOrConversation as dynamic).id ?? '';
  }

  String? get _userAvatar {
    if (_isConversationModel) {
      return (userOrConversation as ConversationModel).otherUserAvatar;
    }
    return (userOrConversation as dynamic).avatar;
  }

  void showChatHeaderMenu(BuildContext context) {
    debugPrint('📋 [ChatHeader] Showing header menu for: $_userName');
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          overlayEntry?.remove();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full screen transparent barrier
              Positioned.fill(child: Container(color: Colors.transparent)),
              // Menu positioned at top right
              Positioned(
                top: 60, // Position below header
                right: 16, // Align to right side
                child: GestureDetector(
                  onTap: () {}, // Prevent tap through to menu
                  child: ChatHeaderMenu(onClose: () => overlayEntry?.remove()),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void _navigateToUserProfile(BuildContext context) {
    debugPrint('👤 [ChatHeader] Navigating to user profile: $_userName ($_userId)');
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            UserProfileScreen2(
              userId: _userId,
              userName: _userName,
              profileImageUrl: _userAvatar,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(),
      child: Row(
        children: [
          /// Back Button
          GestureDetector(
            onTap: onBack,
            child: Image.asset(
              AppAssets.back,
              width: 24,
              height: 24,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          /// User Avatar (Clickable)
          GestureDetector(
            onTap: () => _navigateToUserProfile(context),
            child: _buildAvatar(),
          ),

          const SizedBox(width: 12),

          /// User Name (Clickable)
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToUserProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),

          /// More Options
          IconButton(
            onPressed: () => showChatHeaderMenu(context),
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  /// Build avatar widget with network image support and fallback
  Widget _buildAvatar() {
    final avatarUrl = _userAvatar;
    debugPrint('👤 [ChatHeader] Building avatar for: $_userName - URL: $avatarUrl');
    
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(
          avatarUrl,
        ),
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.grey, size: 20),
      );
    } else {
      // Fallback to asset image
      return CircleAvatar(
        radius: 20,
        backgroundImage: const AssetImage(AppAssets.profile),
      );
    }
  }
}
