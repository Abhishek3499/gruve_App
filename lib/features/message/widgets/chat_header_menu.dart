import 'package:flutter/material.dart';
import '../../../core/assets.dart';

class ChatHeaderMenu extends StatefulWidget {
  final VoidCallback? onClose;

  const ChatHeaderMenu({super.key, this.onClose});

  @override
  State<ChatHeaderMenu> createState() => _ChatHeaderMenuState();
}

class _ChatHeaderMenuState extends State<ChatHeaderMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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

    // Start animation when widget is created
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleMenuAction(String action) {
    debugPrint(action); // Print action to console
    widget.onClose?.call();
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
              boxShadow: [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Restrict option
                _buildMenuItem(
                  icon: Image.asset(AppAssets.ree, width: 22, height: 22),
                  label: 'Restrict',
                  textColor: Colors.white,
                  onTap: () => _handleMenuAction("Restrict user"),
                ),

                const SizedBox(height: 01),

                // Report option
                _buildMenuItem(
                  icon: Image.asset(AppAssets.repor, width: 22, height: 22),
                  label: 'Report',
                  textColor: Colors.redAccent,
                  onTap: () => _handleMenuAction("Report user"),
                ),

                const SizedBox(height: 01),

                // Block option
                _buildMenuItem(
                  icon: Image.asset(
                    AppAssets.blockIcon,
                    width: 20,
                    height: 20,
                  ),
                  label: 'Block',
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
