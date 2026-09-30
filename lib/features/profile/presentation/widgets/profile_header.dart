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
  final VoidCallback? onAvatarLongPress;
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
    this.onAvatarLongPress,
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
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 2, bottom: 0),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.menu, color: Colors.white, size: 19),
              onPressed: () {
                AppLogger.d("[ProfileHeader] Menu button tapped");
                ProfileMenuDrawer.show(context, profileImage: profileImage);
              },
            ),
          ),
        ),
        const SizedBox(height: 3),

        /// Avatar + User Info Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Avatar with Neon Glow and Camera Badge
              StoryAvatarIndicator(
                profileImage: profileImage,
                radius: 26,
                hasActiveStory: hasActiveStory,
                // Seen/unseen doesn't apply to your own story — always show
                // the vivid ring (never the faded "seen" style) while active.
                hasUnseenStory: hasActiveStory,
                hasCloseFriendsStory: hasCloseFriendsStory,
                showCameraIcon: true,
                onCameraTap: onAvatarCameraTap,
                onLongPress: onAvatarLongPress,
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
              const SizedBox(width: 14),

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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      username.isNotEmpty ? username : "@username",
                      style: const TextStyle(
                        color: Color(0xFFBA68C8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        bio.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          height: 1.2,
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
        const SizedBox(height: 8),

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
              const SizedBox(width: 10),
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
