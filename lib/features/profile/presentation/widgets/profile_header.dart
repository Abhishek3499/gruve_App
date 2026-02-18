import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';

import 'edit_profile_button.dart';
import 'subscribe_button.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({super.key, required this.user});

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
              child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
          ],
        ),

        const SizedBox(height: 40),

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
                      color: const Color(0xFF7D63D1).withOpacity(0.8),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7D63D1).withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(user.profileImage),
                ),
              ),

              const SizedBox(width: 25),

              /// Name + Username + Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    Text(
                      user.username,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      user.handle,
                      style: const TextStyle(
                        color: Color(0xFF9544A7),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Conditional button: Edit Profile for current user, Subscribe for others
                    if (user.isCurrentUser)
                      const EditProfileButton()
                    else
                      SubscribeButton(
                        isSubscribed: user.isSubscribed,
                        onTap: () {
                          print("${user.isSubscribed ? 'Unsubscribe' : 'Subscribe'} Clicked for ${user.username}");
                          // Here you would handle subscription logic
                          // For now, just print the action
                        },
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
