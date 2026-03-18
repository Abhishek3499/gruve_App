import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class MusicScreen extends StatelessWidget {
  final String? musicId;
  final String? musicTitle;
  final String? musicUrl;
  final String? userName;
  final String? profileImageUrl;

  const MusicScreen({
    super.key,
    this.musicId,
    this.musicTitle,
    this.musicUrl,
    this.userName,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildMusicHeader(), // Redesigned for Hashtag style
              const SizedBox(height: 25),
              _buildGalleryGrid(),
            ],
          ),
        ),
      ),
    );
  }

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

  /// 🎵 Music/Hashtag Header (Exact SS Match)
  Widget _buildMusicHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Music Cover Image
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(
                      AppAssets.img2,
                    ), // Replace with music cover asset
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "#mindchargedbody",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "#mindchargedbody",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "1.7B Plays",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Shoot Video Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 101, 15, 90), // ✅ main pink
                            Color(
                              0xFF72008D,
                            ), // ✅ dark purple (inner shadow tone)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Color(
                              0x996BA9F6,
                            ), // ✅ blue shadow with 60% opacity
                            blurRadius: 02,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Shoot Video",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🖼️ Gallery Grid with View Counts
  Widget _buildGalleryGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _gridItem(AppAssets.img1, 160, "26.3 M"),
                    _gridItem(AppAssets.frame3, 280, "26.3 M"),
                    _gridItem(AppAssets.frame3, 280, "26.3 M"),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _gridItem(AppAssets.frame1, 300, "26.3 M"),
                    _gridItem(AppAssets.frame2, 200, "26.3 M"),
                    _gridItem(AppAssets.frame1, 300, "26.3 M"),
                    _gridItem(AppAssets.frame2, 200, "26.3 M"),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _gridItem("", 120, "26.3 M", isBlack: true),
                    _gridItem(AppAssets.frame1, 240, "26.3 M"),
                    _gridItem("", 260, "26.3 M", isBlack: true),
                    _gridItem(AppAssets.frame1, 240, "26.3 M"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridItem(
    String assetPath,
    double height,
    String views, {
    bool isBlack = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isBlack ? Colors.black : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Stack(
        children: [
          if (!isBlack && assetPath.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(assetPath, fit: BoxFit.cover),
              ),
            ),
          // View Count Overlay (Bottom Left)
          Positioned(
            bottom: 12,
            left: 12,
            child: Row(
              children: [
                const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  views,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
