import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Reusable Instagram / Gruve style story avatar.
///
/// Unlike the feed's ring (no ring at all once seen), the profile avatar
/// keeps a low-opacity faded ring once already viewed, so it's still clear
/// this user has/had an active story. Priority (first match wins):
/// close-friends (green, faded once seen) > unseen colorful gradient >
/// seen (all-viewed) faded ring > no story at all, no ring.
/// - Supports camera badge overlay when [showCameraIcon] is true
/// - Supports tap on avatar and camera badge independently
/// - Works with network images, local assets, and fallbacks
class StoryAvatarIndicator extends StatelessWidget {
  final String profileImage;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCameraTap;
  final bool showCameraIcon;
  final IconData? badgeIcon;
  final bool enableNavigation;
  final bool hasActiveStory;
  final bool hasUnseenStory;
  final bool hasCloseFriendsStory;
  final double badgeSize;
  final double badgeIconSize;
  final double badgeBottom;
  final double badgeRight;
  final double ringWidth;
  final double ringGap;
  final Color innerBackgroundColor;

  const StoryAvatarIndicator({
    super.key,
    required this.profileImage,
    this.radius = 36,
    this.onTap,
    this.onLongPress,
    this.onCameraTap,
    this.showCameraIcon = false,
    this.badgeIcon,
    this.enableNavigation = true,
    this.hasActiveStory = false,
    this.hasUnseenStory = false,
    this.hasCloseFriendsStory = false,
    this.badgeSize = 24.3,
    this.badgeIconSize = 14.8,
    this.badgeBottom = 5.0,
    this.badgeRight = 1.0,
    this.ringWidth = 2.0,
    this.ringGap = 2.0,
    this.innerBackgroundColor = const Color(0xFF130722),
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatarContent();
    final canOpenStory = enableNavigation && onTap != null;

    final avatarInteractive = (canOpenStory || onLongPress != null)
        ? GestureDetector(
            onTap: canOpenStory
                ? () {
                    AppLogger.d(
                      '👆 [StoryAvatarIndicator] tapped hasActiveStory=$hasActiveStory',
                    );
                    onTap!();
                  }
                : null,
            onLongPress: onLongPress,
            child: avatar,
          )
        : avatar;

    if (!showCameraIcon) {
      return avatarInteractive;
    }

    final outerDimension = (radius * 2) + (ringWidth * 2) + (ringGap * 2);

    // Avatar with edit/camera badge at bottom-right
    return SizedBox(
      width: outerDimension,
      height: outerDimension,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarInteractive,
          Positioned(
            bottom: badgeBottom,
            right: badgeRight,
            child: GestureDetector(
              onTap: onCameraTap ?? onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA3FE8), Color(0xFF7000FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B2FC9).withValues(alpha: 0.6),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    badgeIcon ?? Icons.add,
                    color: Colors.white,
                    size: badgeIconSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    final avatarDiameter = radius * 2;
    final ImageProvider imageProvider = profileImage.isNotEmpty
        ? (profileImage.startsWith('http')
              ? NetworkImage(profileImage) as ImageProvider
              : (profileImage.startsWith('assets')
                    ? AssetImage(profileImage)
                    : AssetImage(AppAssets.profile)))
        : const AssetImage(AppAssets.profile);

    final avatarCore = Container(
      width: avatarDiameter,
      height: avatarDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: innerBackgroundColor,
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );

    final Gradient? ringGradient;
    if (hasCloseFriendsStory && !hasUnseenStory) {
      // Seen — same green identity, faded via opacity.
      ringGradient = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF2ECC40).withValues(alpha: 0.45),
          const Color(0xFF2ECC40).withValues(alpha: 0.18),
          const Color(0xFF2ECC40).withValues(alpha: 0.45),
        ],
      );
    } else if (hasCloseFriendsStory) {
      ringGradient = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF6DD400), Color(0xFF2ECC40), Color(0xFF00C853)],
      );
    } else if (hasUnseenStory) {
      ringGradient = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFFEDA75),
          Color(0xFFFA7E1E),
          Color(0xFFD62976),
          Color(0xFF962FBF),
        ],
      );
    } else if (hasActiveStory) {
      // Seen — same ring, faded via opacity rather than a solid gray.
      ringGradient = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.45),
        ],
      );
    } else {
      ringGradient = null;
    }

    if (ringGradient == null) {
      return avatarCore;
    }

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ringGradient,
        boxShadow: [
          BoxShadow(
            color:
                (hasCloseFriendsStory
                        ? const Color(0xFF2ECC40)
                        : const Color(0xFFD500F9))
                    .withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(ringGap),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: innerBackgroundColor,
        ),
        child: avatarCore,
      ),
    );
  }
}
