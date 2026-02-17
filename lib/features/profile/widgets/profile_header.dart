import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/assets.dart';
import 'edit_profile_button.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top row with three dots menu
        Row(
          children: [
            const SizedBox(width: 20),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openEndDrawer();
              },
              child: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
        
        const SizedBox(height: 20),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 20),
            
            /// Avatar with premium glow and shadow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Strong outer glow
                  BoxShadow(
                    color: const Color(0xFF7D63D1).withOpacity(0.8),
                    blurRadius: 30,
                    spreadRadius: 3,
                  ),
                  // Neon ring effect
                  BoxShadow(
                    color: const Color(0xFF7D63D1).withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  // Depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(AppAssets.profile),
              ),
            ),
            
            const Spacer(),
            
            /// User info on the right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Anastasia Adams",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "@nastasia__",
                  style: TextStyle(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 20),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Edit Profile Button
        const EditProfileButton(),
      ],
    );
  }
}
