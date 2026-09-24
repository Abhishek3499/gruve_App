import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Reusable Instagram / Gruve style story avatar.
///
/// - Shows a neon gradient ring by default or an active story ring when [hasActiveStory] is true
/// - Supports camera badge overlay when [showCameraIcon] is true
/// - Supports tap on avatar and camera badge independently
/// - Works with network images, local assets, and fallbacks
class StoryAvatarIndicator extends StatelessWidget {
  final String profileImage;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onCameraTap;
  final bool showCameraIcon;
  final bool enableNavigation;
  final bool hasActiveStory;
  final bool hasCloseFriendsStory;
  final bool isViewed;
  final double ringWidth;
  final double ringGap;
  final Color innerBackgroundColor;

  const StoryAvatarIndicator({
    super.key,
    required this.profileImage,
    this.radius = 48,
    this.onTap,
    this.onCameraTap,
    this.showCameraIcon = false,
    this.enableNavigation = true,
    this.hasActiveStory = false,
    this.hasCloseFriendsStory = false,
    this.isViewed = false,
    this.ringWidth = 2.8,
    this.ringGap = 2.4,
    this.innerBackgroundColor = const Color(0xFF130722),
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatarContent();
    final canOpenStory = enableNavigation && onTap != null;

    final avatarInteractive = canOpenStory
        ? GestureDetector(
            onTap: () {
              AppLogger.d(
                '👆 [StoryAvatarIndicator] tapped hasActiveStory=$hasActiveStory',
              );
              onTap!();
            },
            child: avatar,
          )
        : avatar;

    if (!showCameraIcon) {
      return avatarInteractive;
    }

    // Avatar with camera badge at bottom-right
    return SizedBox(
      width: (radius * 2) + (ringWidth * 2) + (ringGap * 2) + 6,
      height: (radius * 2) + (ringWidth * 2) + (ringGap * 2) + 6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarInteractive,
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: onCameraTap ?? onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B2FC9), Color(0xFF6B1D9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFD946EF),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B2FC9).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 16,
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

    // Neon or Story ring gradient
    final Gradient ringGradient;
    if (hasCloseFriendsStory) {
      // Instagram-style close friends ring — solid green, independent of hasActiveStory.
      ringGradient = isViewed
          ? const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF9E9E9E), Color(0xFF757575), Color(0xFFBDBDBD)],
            )
          : const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF6DD400), Color(0xFF2ECC40), Color(0xFF00C853)],
            );
    } else if (hasActiveStory) {
      ringGradient = isViewed
          ? const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF9E9E9E), Color(0xFF757575), Color(0xFFBDBDBD)],
            )
          : const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
              ],
            );
    } else {
      ringGradient = const SweepGradient(
        colors: [
          Color(0xFF00E5FF), // cyan
          Color(0xFFD500F9), // purple
          Color(0xFFFF4081), // pink
          Color(0xFF00E5FF), // back to cyan
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ringGradient,
        boxShadow: [
          BoxShadow(
            color: (hasCloseFriendsStory
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
