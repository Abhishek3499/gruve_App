import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/assets.dart';
import 'package:gruve_app/screens/auth/api/models/edit_profile_response.dart';

import '../models/profile_model.dart';
import 'edit_profile_button.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final String username;
  final String profileImage;
  final ValueChanged<EditProfileResponse>? onProfileUpdated;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.username,
    required this.profileImage,
    this.onProfileUpdated,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Top 3 dots
        Row(
          children: [
            const SizedBox(width: 20),
            const Spacer(),
            GestureDetector(
              onTap: () {
                debugPrint("[ProfileHeader] Menu button tapped");
                Scaffold.of(context).openEndDrawer();
              },
              child: const Icon(Icons.menu, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
          ],
        ),
        const SizedBox(height: 20),
        /// Avatar + User Info Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7D63D1).withValues(alpha: 0.8),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7D63D1).withValues(alpha: 0.6),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: (profileImage.isNotEmpty)
                      ? NetworkImage(profileImage)
                      : AssetImage(AppAssets.profile) as ImageProvider,
                ),
              ),
              const SizedBox(width: 25),
              /// Name + Username + Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : "No Name",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      username.isNotEmpty ? username : "@username",
                      style: const TextStyle(
                        color: Color(0xFF9544A7),
                        fontSize: 16,
                        fontWeight: FontWeight(700),
                      ),
                    ),
                    const SizedBox(height: 25),
                    EditProfileButton(
                      profile: ProfileModel(
                        username: username,
                        bio: "",
                        email: "",
                        profileImagePath: profileImage,
                      ),
                      onProfileUpdated: onProfileUpdated,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
