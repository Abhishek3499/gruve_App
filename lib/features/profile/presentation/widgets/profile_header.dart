import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/story_preview/utils/story_utils.dart';
import 'package:gruve_app/features/profile/presentation/widgets/story_avatar_indicator.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_menu_drawer.dart';
import 'package:gruve_app/features/profile/presentation/widgets/stats_row.dart';
import 'package:gruve_app/features/camera/presentation/controller/camera_handler.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final String username;
  final String bio;
  final String profileImage;
  final int subscribersCount;
  final int likesCount;
  final int videosCount;
  final VoidCallback? onSubscribersTap;
  final VoidCallback? onSubscribedTap;
  final VoidCallback? onAvatarCameraTap;
  final VoidCallback? onAvatarLongPress;
  final VoidCallback? onAddTap;
  final VoidCallback? onUsernameTap;
  final bool hasActiveStory;
  final bool hasCloseFriendsStory;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.username,
    this.bio = '',
    required this.profileImage,
    this.subscribersCount = 0,
    this.likesCount = 0,
    this.videosCount = 0,
    this.onSubscribersTap,
    this.onSubscribedTap,
    this.onAvatarCameraTap,
    this.onAvatarLongPress,
    this.onAddTap,
    this.onUsernameTap,
    this.hasActiveStory = false,
    this.hasCloseFriendsStory = false,
  });

  String _formatUsername(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '@username';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final displayUsername = _formatUsername(username);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Top Bar: [+] on left, [username] centered, [☰] on right
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              /// Plus Icon (Left)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  if (onAddTap != null) {
                    onAddTap!();
                  } else if (onAvatarCameraTap != null) {
                    onAvatarCameraTap!();
                  } else {
                    CameraHandler.openCamera(context);
                  }
                },
              ),

              /// Username in Center (no chevron arrow)
              Expanded(
                child: GestureDetector(
                  onTap: onUsernameTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    displayUsername,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),

              /// Menu Icon (Right)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () {
                  AppLogger.d("[ProfileHeader] Menu button tapped");
                  ProfileMenuDrawer.show(
                    context,
                    profileImage: profileImage,
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        /// Avatar (Left) + [Full Name at top & Stats Row down] (Right)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Avatar: 80 dp outer, 72 dp inner image, 28 dp add badge
              StoryAvatarIndicator(
                profileImage: profileImage,
                radius: 36,
                ringWidth: 2.0,
                ringGap: 2.0,
                hasActiveStory: hasActiveStory,
                hasUnseenStory: hasActiveStory,
                hasCloseFriendsStory: hasCloseFriendsStory,
                showCameraIcon: true,
                badgeIcon: Icons.add,
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

              /// Right Section: Full Name at Top + Stats Row underneath
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Full Name (Top)
                    Padding(
                      padding: const EdgeInsets.only(left: 1),
                      child: Text(
                        fullName.isNotEmpty ? fullName : "No Name",
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14.25,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// Stats Row (Down of Full Name)
                    StatsRow(
                      subscribersCount: subscribersCount,
                      likesCount: likesCount,
                      videosCount: videosCount,
                      onSubscribersTap: onSubscribersTap,
                      onSubscribedTap: onSubscribedTap,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// Bio section (Down of Avatar across full width)
        if (bio.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProfileBioView(
              bio: bio,
              fullName: fullName,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact Gen-Z friendly bio view with 2-line limit and inline expandable "... more" / "less" action.
class ProfileBioView extends StatefulWidget {
  final String bio;
  final String fullName;

  const ProfileBioView({
    super.key,
    required this.bio,
    this.fullName = '',
  });

  @override
  State<ProfileBioView> createState() => _ProfileBioViewState();
}

class _ProfileBioViewState extends State<ProfileBioView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cleanBio = widget.bio.trim();
    if (cleanBio.isEmpty) return const SizedBox.shrink();

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      height: 20.0 / 14.0, // ~20sp line height
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: cleanBio, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final bool isOverflowing = textPainter.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(
            cleanBio,
            style: textStyle,
            maxLines: 2,
          );
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cleanBio,
                style: textStyle,
                maxLines: _isExpanded ? null : 2,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? "less" : "... more",
                      style: const TextStyle(
                        color: Color(0xFFFF3AFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: const Color(0xFFFF3AFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
