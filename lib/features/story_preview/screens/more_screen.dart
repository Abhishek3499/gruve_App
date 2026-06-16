import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7A1FA2),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label, {
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF311B36),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Header Row
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Archive stories while they're active.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),

              // Option list
              _buildOption(
                context,
                "Delete Story",
                textColor: const Color(0xFFE53935),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar(context, "Deleting story...");
                },
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),
              
              _buildOption(
                context,
                "Archive",
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar(context, "Story archived successfully");
                },
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),

              _buildOption(
                context,
                "Highlight",
                onTap: () {
                  Navigator.pop(context, 'highlight');
                },
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),

              _buildOption(
                context,
                "Save...",
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar(context, "Saving story to device...");
                },
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),

              _buildOption(
                context,
                "Story settings",
                onTap: () {
                  Navigator.pop(context, 'settings');
                },
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),

              _buildOption(
                context,
                "Turn off commenting",
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar(context, "Comments turned off for this story");
                },
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1,
              ),

              const SizedBox(height: 16),

              // Close button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF833FB0), Color(0xFF511263)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF833FB0).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
