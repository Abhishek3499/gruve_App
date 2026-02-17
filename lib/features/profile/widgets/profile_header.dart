import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/assets.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 🔥 PREMIUM LEFT AVATAR
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Deep purple glow
                BoxShadow(
                  color: const Color(0xFF7D63D1).withOpacity(0.9),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                // Soft outer aura
                BoxShadow(
                  color: const Color(0xFF7D63D1).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                // Depth shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: AssetImage(AppAssets.profile),
              ),
            ),
          ),

          const SizedBox(width: 20),

          /// USER INFO
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Anastasia Adams",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "@nastasia__",
                style: TextStyle(color: AppColors.white70, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
