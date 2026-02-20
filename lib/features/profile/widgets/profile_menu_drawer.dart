import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ProfileMenuDrawer extends StatelessWidget {
  const ProfileMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // overlay
      body: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 285,
          margin: const EdgeInsets.symmetric(vertical: 01),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // Top color
                Color(0xFF9544A7),
                Color(0xFF42174C), // Bottom color // 👈 Bottom
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// MENU LIST
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _menuItem(AppAssets.account, "Account"),
                      _menuItem(AppAssets.insight, "Insight"),
                      _menuItem(AppAssets.wallet, "Wallet"),
                      _menuItem(AppAssets.blocked, "Blocked"),
                      _menuItem(Icons.lock, "Account Privacy"),
                      _menuItem(AppAssets.archive, "Archive"),
                      _menuItem(AppAssets.saved, "Saved"),
                      _menuItem(AppAssets.language, "Language"),
                      _menuItem(Icons.help_outline, "Help Center"),
                      _menuItem(AppAssets.terms, "Terms & Conditions"),
                    ],
                  ),
                ),

                /// 🔥 LOGOUT + FOOTER SECTION (BOTTOM FIXED)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      /// Logout
                      Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.white, size: 22),
                          SizedBox(width: 16),
                          Text(
                            "Log out",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      /// Made in India
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/splash_screen_logo/image 43.png',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'Made in India',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'Syncopate',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// Powered by
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Powered by  ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Syncopate',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'Hardkore Tech',
                              style: TextStyle(
                                color: Color(0xFF72008D),
                                fontSize: 11,
                                fontFamily: 'Syncopate',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(dynamic icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          /// 👇 If IconData → use Icon
          icon is IconData
              ? Icon(icon, color: Colors.white, size: 22)
              /// 👇 If Asset String → use Image.asset
              : Image.asset(
                  icon,
                  width: 22,
                  height: 22,
                  color: Colors.white, // remove if multi-color PNG
                ),

          const SizedBox(width: 16),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
