import 'package:flutter/material.dart';

enum MessageAction {
  reply,
  forward,
  pin,
  report,
  delete,
}

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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF311B36), // Dark purple background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            icon: Icons.reply,
            label: 'Reply',
            color: Colors.white,
            isSelected: selectedAction == MessageAction.reply,
            onTap: () => onActionSelected?.call(MessageAction.reply),
          ),

          const Divider(height: 1, color: Color(0xFF4A4A5A)),

          // Forward
          _buildMenuItem(
            icon: Icons.send,
            label: 'Forward',
            color: Colors.white,
            isSelected: selectedAction == MessageAction.forward,
            onTap: () => onActionSelected?.call(MessageAction.forward),
          ),

          const Divider(height: 1, color: Color(0xFF4A4A5A)),

          // Pin
          _buildMenuItem(
            icon: Icons.push_pin,
            label: 'Pin',
            color: Colors.white,
            isSelected: selectedAction == MessageAction.pin,
            onTap: () => onActionSelected?.call(MessageAction.pin),
          ),

          const Divider(height: 1, color: Color(0xFF4A4A5A)),

          // Report
          _buildMenuItem(
            icon: Icons.report,
            label: 'Report',
            color: const Color(0xFFF51829), // Red for danger
            isSelected: selectedAction == MessageAction.report,
            onTap: () => onActionSelected?.call(MessageAction.report),
          ),

          const Divider(height: 1, color: Color(0xFF4A4A5A)),

          // Delete
          _buildMenuItem(
            icon: Icons.delete,
            label: 'Delete',
            color: const Color(0xFFF51829), // Red for danger
            isSelected: selectedAction == MessageAction.delete,
            onTap: () => onActionSelected?.call(MessageAction.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
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
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
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
