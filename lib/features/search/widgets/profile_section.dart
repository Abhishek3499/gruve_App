import 'package:flutter/material.dart';

import 'profile_avatar.dart';

class ProfileSection extends StatelessWidget {
  final String username;
  final String subtitle;
  final String stats;
  final String profileImage; // 👈 NEW

  const ProfileSection({
    super.key,
    required this.username,
    required this.subtitle,
    required this.stats,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 01),
      child: Row(
        children: [
          ProfileAvatar(imagePath: profileImage, size: 80),
          const SizedBox(width: 01),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'syncopate',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.amber, fontSize: 13),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Text(
                stats,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
