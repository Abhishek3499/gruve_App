import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../user_profile/utils/report_user_flow.dart';
import 'block/block_user_widget.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ChatHeaderMenu extends StatefulWidget {
  final VoidCallback? onClose;

  /// Navigator that owns [ChatScreen] (used to pop the chat with a result after block succeeds).
  final NavigatorState chatNavigator;
  final String userId;
  final String userName;
  final bool isBlocked;

  const ChatHeaderMenu({
    super.key,
    this.onClose,
    required this.chatNavigator,
    required this.userId,
    required this.userName,
    required this.isBlocked,
  });

  @override
  State<ChatHeaderMenu> createState() => _ChatHeaderMenuState();
}

class _ChatHeaderMenuState extends State<ChatHeaderMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late final bool _initialBlockState;

  @override
  void initState() {
    super.initState();
    _initialBlockState = widget.isBlocked;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleMenuAction(String action) {
    AppLogger.d(action);

    if (action == "Report user") {
      _showReportSheet();
    } else if (action == "Block user") {
      _showBlockDialog();
    } else {
      widget.onClose?.call();
    }
  }

  void _showReportSheet() {
    final chatNavigator = widget.chatNavigator;
    widget.onClose?.call();

    ReportUserFlow.showAndSubmit(
      context: chatNavigator.context,
      userId: widget.userId,
    );
  }

  void _showBlockDialog() async {
    final chatNavigator = widget.chatNavigator;
    final userName = widget.userName;
    final userId = widget.userId;
    final initialBlockState = _initialBlockState;

    widget.onClose?.call();

    final isBlockedAfterToggle = await showGeneralDialog<bool>(
      context: chatNavigator.context,
      barrierDismissible: false,
      barrierLabel: 'BlockUserDialog',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BlockUserWidget(
          name: userName,
          username: "@$userName",
          userId: userId,
          isBlocked: initialBlockState,
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );

    if (isBlockedAfterToggle == null) return;

    if (isBlockedAfterToggle && chatNavigator.mounted) {
      chatNavigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 180,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _buildMenuItem(
                //   icon: Image.asset(AppAssets.ree, width: 22, height: 22),
                //   label: 'Restrict',
                //   textColor: Colors.white,
                //   onTap: () => _handleMenuAction("Restrict user"),
                // ),
                const SizedBox(height: 1),

                _buildMenuItem(
                  icon: Image.asset(AppAssets.repor, width: 22, height: 22),
                  label: 'Report',
                  textColor: Colors.redAccent,
                  onTap: () => _handleMenuAction("Report user"),
                ),

                const SizedBox(height: 1),

                _buildMenuItem(
                  icon: Image.asset(AppAssets.blockIcon, width: 20, height: 20),
                  label: _initialBlockState ? 'Unblock' : 'Block',
                  textColor: Colors.redAccent,
                  onTap: () => _handleMenuAction("Block user"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required Widget icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
