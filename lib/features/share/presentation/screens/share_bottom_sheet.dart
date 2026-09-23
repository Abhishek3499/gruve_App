import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/features/share/presentation/notifiers/post_share_notifier.dart';
import 'package:gruve_app/features/share/presentation/widgets/share_user_grid.dart';
import 'package:gruve_app/features/share/presentation/widgets/share_social_buttons.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class ShareBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const ShareBottomSheet({super.key, required this.postId});

  @override
  ConsumerState<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<ShareBottomSheet> {
  @override
  void dispose() {
    // Clean up the selection when the bottom sheet is closed
    final shareNotifier = ref.read(postShareNotifierProvider.notifier);
    Future.microtask(() {
      shareNotifier.clearSelection();
    });
    super.dispose();
  }

  Widget _buildSendButton(
    BuildContext context,
    Set<SearchUser> selectedUsers,
    bool isSending,
  ) {
    return Padding(
      key: const ValueKey('send'),
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(20),
        vertical: context.rh(12),
      ),
      child: GestureDetector(
        onTap: () async {
          final success = await ref
              .read(postShareNotifierProvider.notifier)
              .sharePost(widget.postId);
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
    final (selectedUsers, isSending) = ref.watch(
      postShareNotifierProvider.select((s) => (s.selectedUsers, s.isSending)),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.softPurple, AppColors.sheetDark],
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
            const Expanded(flex: 3, child: ShareUserGrid()),

            // Social share buttons or send button with smooth flow transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: selectedUsers.isNotEmpty
                  ? _buildSendButton(context, selectedUsers, isSending)
                  : ShareSocialButtons(
                      key: const ValueKey('social'),
                      postId: widget.postId,
                    ),
            ),

            SizedBox(height: context.rh(20)),
          ],
        ),
      ),
    );
  }
}
