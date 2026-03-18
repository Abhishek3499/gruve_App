import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

enum MessageAction { reply, forward, pin, report, delete }

class MessagePopupMenu extends StatelessWidget {
  final MessageAction? selectedAction;
  final Function(MessageAction)? onActionSelected;

  const MessagePopupMenu({
    super.key,
    this.selectedAction,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF311B36), // Dark purple background
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply
                _buildMenuItem(
                  icon: AppAssets.reply,
                  label: 'Reply',
                  color: Colors.white,
                  isSelected: selectedAction == MessageAction.reply,
                  onTap: () => onActionSelected?.call(MessageAction.reply),
                ),

                const SizedBox(height: 14),

                // Copy
                _buildMenuItem(
                  icon: AppAssets.forward,
                     label: 'forward',
                  color: Colors.white,
                  isSelected: selectedAction == MessageAction.forward,
                  onTap: () => onActionSelected?.call(MessageAction.forward),
                ),

                const SizedBox(height: 14),
                _buildMenuItem(
                  icon: AppAssets.pin,
                  label: 'pin',
                  color: Colors.white,
                  isSelected: selectedAction == MessageAction.forward,
                  onTap: () => onActionSelected?.call(MessageAction.forward),
                ),

                const SizedBox(height: 14),

                // Delete
                _buildMenuItem(
                  icon: AppAssets.report,
                  label: 'report',
                  color: const Color(0xFFF51829), // Red for danger
                  isSelected: selectedAction == MessageAction.delete,
                  onTap: () => onActionSelected?.call(MessageAction.delete),
                ),

                const SizedBox(height: 14),

                // Forward
                _buildMenuItem(
                  icon: AppAssets.report,
                  label: 'delete',
                  color: const Color(0xFFF51829), // Red for danger
                  isSelected: selectedAction == MessageAction.delete,
                  onTap: () => onActionSelected?.call(MessageAction.delete),
                ),
              ],
            ),
          ),
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
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
