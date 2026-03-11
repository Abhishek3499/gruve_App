import 'package:flutter/material.dart';

enum DeleteOption {
  fromMe,
  fromEveryone,
}

class DeleteMessageDialog {
  final Function(DeleteOption) onDeleteSelected;

  const DeleteMessageDialog({
    required this.onDeleteSelected,
  });

  Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF311B36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Delete Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            
            // Options
            Column(
              children: [
                // Delete from me
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteSelected(DeleteOption.fromMe);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF72008D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Delete from me',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Delete from everyone
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteSelected(DeleteOption.fromEveryone);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF51829),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Delete from everyone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
