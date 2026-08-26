import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/share/providers/post_share_provider.dart';
import '../widgets/share_user_grid.dart';
import '../widgets/share_social_buttons.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class ShareBottomSheet extends StatefulWidget {
  final String postId;

  const ShareBottomSheet({
    super.key,
    required this.postId,
  });

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  @override
  void dispose() {
    // Clean up the provider selection when the bottom sheet is closed
    final shareProvider = Provider.of<PostShareProvider>(context, listen: false);
    Future.microtask(() {
      shareProvider.clearSelection();
    });
    super.dispose();
  }

  Widget _buildSendButton(BuildContext context, PostShareProvider shareProvider) {
    final selectedUsers = shareProvider.selectedUsers;
    final isSending = shareProvider.isSending;

    return Padding(
      key: const ValueKey('send'),
      padding: EdgeInsets.symmetric(horizontal: context.rw(20), vertical: context.rh(12)),
      child: GestureDetector(
        onTap: () async {
          final success = await shareProvider.sharePost(widget.postId);
          if (success && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          width: double.infinity,
          height: context.rh(50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3AFF), Color(0xFF72008D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3AFF).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isSending
                ? SizedBox(
                    width: context.rw(24),
                    height: context.rh(24),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Send to ${selectedUsers.length} ${selectedUsers.length == 1 ? 'person' : 'people'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(16),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostShareProvider>(
      builder: (context, shareProvider, _) {
        final selectedUsers = shareProvider.selectedUsers;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: context.rh(8)),
                  width: context.rw(65),
                  height: context.rh(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(height: context.rh(20)),

                // User grid with search
                const Expanded(
                  flex: 3,
                  child: ShareUserGrid(),
                ),

                // Social share buttons or send button with smooth flow transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: selectedUsers.isNotEmpty
                      ? _buildSendButton(context, shareProvider)
                      : const ShareSocialButtons(key: ValueKey('social')),
                ),

                SizedBox(height: context.rh(20)),
              ],
            ),
          ),
        );
      },
    );
  }
}
