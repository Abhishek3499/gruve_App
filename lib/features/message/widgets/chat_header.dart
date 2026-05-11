import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/widgets/optimized/optimized_image.dart';
import 'package:gruve_app/features/message/models/conversation_model.dart';
import 'package:gruve_app/features/message/widgets/chat_header_menu.dart';
import 'package:gruve_app/features/user_profiles/widgets/screens/user_profile_screen2.dart';
import '../utils/user_display_helper.dart';

class ChatHeader extends StatelessWidget {
  final dynamic userOrConversation;
  final String? explicitUserName;
  final String? explicitUserId;
  final String? explicitProfileImage;
  final VoidCallback onBack;

  const ChatHeader({
    super.key,
    required this.userOrConversation,
    this.explicitUserName,
    this.explicitUserId,
    this.explicitProfileImage,
    required this.onBack,
  });

  bool get _isConversationModel => userOrConversation is ConversationModel;

  String get _userName {
    final explicitName = explicitUserName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    if (_isConversationModel) {
      final conversation = userOrConversation as ConversationModel;
      return UserDisplayHelper.getDisplayNameForConversation(conversation);
    }

    // Handle legacy user data
    return UserDisplayHelper.getDisplayNameForLegacyUser(userOrConversation);
  }

  String get _userId {
    final explicitId = explicitUserId?.trim();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }

    return UserDisplayHelper.getUserIdForUser(userOrConversation);
  }

  String? get _userAvatar {
    // Priority 1: Explicit profile image parameter
    if (explicitProfileImage != null) {
      return explicitProfileImage;
    }

    // Priority 2: Use centralized helper
    return UserDisplayHelper.getProfileImageForUser(userOrConversation);
  }

  void showChatHeaderMenu(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => overlayEntry?.remove(),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              Positioned(
                top: 60,
                right: 16,
                child: GestureDetector(
                  onTap: () {},
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
            position: Tween<Offset>(
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
      child: Row(
        children: [
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
          GestureDetector(
            onTap: () => _navigateToUserProfile(context),
            child: OptimizedAvatar(
              imageUrl: _userAvatar,
              name: _userName,
              radius: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToUserProfile(context),
              child: Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => showChatHeaderMenu(context),
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
