import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class UserProfileScreen2 extends StatelessWidget {
  final String userId;
  final String userName;
  final String? profileImageUrl;

  const UserProfileScreen2({
    super.key,
    required this.userId,
    required this.userName,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Anti-flash
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildProfileHeader(),
              _buildActionButtons(),
              const SizedBox(height: 10),
              _buildGalleryGrid(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔙 Custom Back Button
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(AppAssets.back, height: 22, width: 22),
          ),
        ],
      ),
    );
  }

  /// 👤 Profile Header with Neon Glow
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : AssetImage(AppAssets.profile) as ImageProvider,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "@${userName.toLowerCase().replaceAll(' ', '')}",
          style: const TextStyle(
            color: Color(0xFFD473FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  /// 🔘 Action Buttons (Profile & Mute)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconButton(Icons.person_outline, "Profile"),
          const SizedBox(width: 100),
          _iconButton(Icons.notifications_off_outlined, "Mute"),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 🖼️ Masonry Gallery Grid (3 Columns logic as per SS)
  Widget _buildGalleryGrid() {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Column 1 ---
            Expanded(
              child: Column(
                children: [
                  _gridItem(AppAssets.img1, 160), // Top Left (Pink Sky)
                  _gridItem(AppAssets.frame2, 280), // Middle Left (Temple/Tree)
                ],
              ),
            ),
            const SizedBox(width: 10),

            // --- Column 2 ---
            Expanded(
              child: Column(
                children: [
                  _gridItem(AppAssets.frame3, 300), // Tall Concert
                  _gridItem(AppAssets.frame1, 200), // B&W Man
                  _gridItem(AppAssets.frame2, 220), // Bottom Concert
                ],
              ),
            ),
            const SizedBox(width: 10),

            // --- Column 3 ---
            Expanded(
              child: Column(
                children: [
                  _gridItem("", 120, isBlack: true), // Top Right Black Box
                  _gridItem(AppAssets.frame2, 240), // Neon Circles
                  _gridItem(AppAssets.img1, 260), // Bottom Right Pink Sky
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🛠️ Reusable Grid Item
  Widget _gridItem(String assetPath, double height, {bool isBlack = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isBlack ? Colors.black : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: isBlack || assetPath.isEmpty
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white10),
                ),
              ),
            ),
    );
  }
}
