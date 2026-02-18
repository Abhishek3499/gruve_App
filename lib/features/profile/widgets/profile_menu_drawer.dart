import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfileMenuDrawer extends StatelessWidget {
  const ProfileMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientTop, AppColors.gradientBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),

              const SizedBox(height: 40),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      icon: Icons.person,
                      title: "Account",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.insights,
                      title: "Insight",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet,
                      title: "Wallet",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.block,
                      title: "Blocked",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.privacy_tip,
                      title: "Account Privacy",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.archive,
                      title: "Archive",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.bookmark,
                      title: "Saved",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.language,
                      title: "Language",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.help_center,
                      title: "Help Center",
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.description,
                      title: "Terms & Conditions",
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Logout at bottom
              Container(
                padding: const EdgeInsets.all(20),
                child: _buildMenuItem(
                  icon: Icons.logout,
                  title: "Log out",
                  onTap: () {},
                  isLogout: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isLogout
                  ? Border.all(color: Colors.red.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout ? Colors.red : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isLogout ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
