import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';

class VideoUserInfo extends StatelessWidget {
  final String username;
  final String caption;
  final String musicTitle;
  final VoidCallback? onSubscribe;

  const VideoUserInfo({
    super.key,
    required this.username,
    required this.caption,
    required this.musicTitle,
    this.onSubscribe,
  });

  String get displayUsername {
    if (username.length <= 15) {
      return username;
    } else {
      return "${username.substring(0, 15)}...";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 14, bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔥 USER ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(AppAssets.user),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserProfileScreen(),
                      ),
                    );
                  },
                  child: Text(
                    displayUsername,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              SizedBox(
                height: 32,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: onSubscribe,
                  child: const Text(
                    "Subscribe",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🔥 CAPTION
          if (caption.isNotEmpty)
            Text(
              caption,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 12),

          /// 🔥 MUSIC + USERS ROW
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 18),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  musicTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 10),

              /// Glass Users Pill
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          "2 users",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
