import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

enum MessageAction { reply, forward, pin, report, delete }

class MessagePopupMenu extends StatefulWidget {
  final MessageAction? selectedAction;
  final Function(MessageAction)? onActionSelected;
  final bool showBlur;
  final VoidCallback? onDeleteMode;
  final bool isDeleteMode;
  final int selectedCount;
  final Function(int)? onMessageToggle;
  final VoidCallback? onDismiss;

  const MessagePopupMenu({
    super.key,
    this.selectedAction,
    this.onActionSelected,
    this.showBlur = false,
    this.onDeleteMode,
    this.isDeleteMode = false,
    this.selectedCount = 0,
    this.onMessageToggle,
    this.onDismiss,
  });

  @override
  State<MessagePopupMenu> createState() => _MessagePopupMenuState();
}

class _MessagePopupMenuState extends State<MessagePopupMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDeleteMode) {
      return _buildDeleteModeBar();
    }
    return _buildPopupMenu();
  }

  Widget _buildPopupMenu() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF311B36),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuItem(
                  icon: AppAssets.reply,
                  label: 'Reply',
                  color: Colors.white,
                  isSelected: widget.selectedAction == MessageAction.reply,
                  onTap: () =>
                      widget.onActionSelected?.call(MessageAction.reply),
                ),
                _buildMenuItem(
                  icon: AppAssets.forward,
                  label: 'Forward',
                  color: Colors.white,
                  isSelected: widget.selectedAction == MessageAction.forward,
                  onTap: () =>
                      widget.onActionSelected?.call(MessageAction.forward),
                ),
                _buildMenuItem(
                  icon: AppAssets.pin,
                  label: 'Pin',
                  color: Colors.white,
                  isSelected: widget.selectedAction == MessageAction.pin,
                  onTap: () => widget.onActionSelected?.call(MessageAction.pin),
                ),
                _buildMenuItem(
                  icon: AppAssets.repor,
                  label: 'Report',
                  color: const Color(0xFFF51829),
                  isSelected: widget.selectedAction == MessageAction.report,
                  onTap: () =>
                      widget.onActionSelected?.call(MessageAction.report),
                ),
                _buildMenuItem(
                  icon: AppAssets.deleted,
                  label: 'Delete',
                  color: const Color(0xFFF51829),
                  isSelected: widget.selectedAction == MessageAction.delete,
                  onTap: () => widget.onDeleteMode?.call(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteModeBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF0d0d1a)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'If this chat is reported, recently deleted message will be included in the report',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF51829),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Delete for you (${widget.selectedCount})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(icon, color: color, width: 20, height: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Blur Overlay
// ─────────────────────────────────────────────
class MessageBlurOverlay extends StatelessWidget {
  final Widget child;
  final bool showBlur;
  final VoidCallback? onTapOutside;

  const MessageBlurOverlay({
    super.key,
    required this.child,
    this.showBlur = false,
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showBlur)
          Positioned.fill(
            child: GestureDetector(
              onTap: onTapOutside,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withValues(alpha: 0.15)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MessageWithCheckbox — purple circle style
// ─────────────────────────────────────────────
class MessageWithCheckbox extends StatelessWidget {
  final Widget message;
  final bool isSelected;
  final VoidCallback? onTap;
  final void Function(bool?)? onCheckboxChanged;

  const MessageWithCheckbox({
    super.key,
    required this.message,
    this.isSelected = false,
    this.onTap,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ Purple circle — screenshot jaisa
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(left: 8, right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF7B2FBE) // purple filled when selected
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7B2FBE)
                    : Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          Expanded(child: message),
        ],
      ),
    );
  }
}
