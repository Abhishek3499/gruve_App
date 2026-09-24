import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_response.dart';
import 'package:gruve_app/features/story_preview/utils/story_utils.dart';
import 'package:gruve_app/features/account/domain/entities/profile_model.dart';
import 'package:gruve_app/features/profile/presentation/widgets/edit_profile_button.dart';
import 'package:gruve_app/features/profile/presentation/widgets/story_avatar_indicator.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_menu_drawer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:share_plus/share_plus.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final String username;
  final String bio;
  final String profileImage;
  final ValueChanged<EditProfileResponse>? onProfileUpdated;
  final VoidCallback? onAvatarCameraTap;
  final VoidCallback? onShareProfileTap;
  final bool hasActiveStory;
  final bool hasCloseFriendsStory;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.username,
    this.bio = '',
    required this.profileImage,
    this.onProfileUpdated,
    this.onAvatarCameraTap,
    this.onShareProfileTap,
    this.hasActiveStory = false,
    this.hasCloseFriendsStory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Top menu icon (Right aligned)
        Row(
          children: [
            const SizedBox(width: 20),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () {
                AppLogger.d("[ProfileHeader] Menu button tapped");
                ProfileMenuDrawer.show(context, profileImage: profileImage);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 10),

        /// Avatar + User Info Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Avatar with Neon Glow and Camera Badge
              StoryAvatarIndicator(
                profileImage: profileImage,
                hasActiveStory: hasActiveStory,
                hasCloseFriendsStory: hasCloseFriendsStory,
                showCameraIcon: true,
                onCameraTap: onAvatarCameraTap,
                onTap: () async {
                  if (hasActiveStory) {
                    AppLogger.d(
                      '[ProfileHeader] Opening own story - isOwnProfile: true',
                    );
                    await StoryUtils.navigateToStoryView(
                      context,
                      userId: null,
                      displayName: fullName,
                      username: username,
                      avatar: profileImage,
                      isOwnProfile: true,
                    );
                  } else if (onAvatarCameraTap != null) {
                    onAvatarCameraTap!();
                  }
                },
              ),
              const SizedBox(width: 18),

              /// User Info: Name, Username, Bio (NO blue tick)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : "No Name",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username.isNotEmpty ? username : "@username",
                      style: const TextStyle(
                        color: Color(0xFFBA68C8),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        bio.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        /// Action Buttons: Edit Profile & Share Profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: EditProfileButton(
                  profile: ProfileModel(
                    username: username,
                    bio: bio,
                    email: "",
                    profileImagePath: profileImage,
                  ),
                  onProfileUpdated: onProfileUpdated,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShareProfileButton(
                  onTap: () {
                    if (onShareProfileTap != null) {
                      onShareProfileTap!();
                    } else {
                      final cleanUsername = username.replaceAll('@', '').trim();
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'Check out $fullName (@$cleanUsername) on Gruve!\nhttps://gruve.app/user/$cleanUsername',
                          subject: '$fullName on Gruve',
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
