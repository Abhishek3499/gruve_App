import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

/// Reusable Instagram-style story avatar.
///
/// - Shows a gradient ring when [hasActiveStory] is true
/// - Falls back to a normal avatar when there is no active story
/// - Supports viewed/unviewed ring states
/// - Works with network images and local placeholder assets
class StoryAvatarIndicator extends StatelessWidget {
  final String profileImage;
  final double radius;
  final VoidCallback? onTap;
  final bool enableNavigation;
  final bool hasActiveStory;
  final bool isViewed;
  final double ringWidth;
  final double ringGap;
  final Color innerBackgroundColor;

  const StoryAvatarIndicator({
    super.key,
    required this.profileImage,
    this.radius = 50,
    this.onTap,
    this.enableNavigation = true,
    this.hasActiveStory = false,
    this.isViewed = false,
    this.ringWidth = 3.2,
    this.ringGap = 2.4,
    this.innerBackgroundColor = const Color(0xFF212235),
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🟣 [StoryAvatarIndicator] build hasActiveStory=$hasActiveStory isViewed=$isViewed radius=$radius',
    );

    final avatar = _buildAvatarContent();
    final child = enableNavigation
        ? GestureDetector(
            onTap: () {
              debugPrint(
                '👆 [StoryAvatarIndicator] tapped hasActiveStory=$hasActiveStory',
              );
              onTap?.call();
            },
            child: avatar,
          )
        : avatar;

    return child;
  }

  Widget _buildAvatarContent() {
    final avatarDiameter = radius * 2;
    final ImageProvider imageProvider = profileImage.isNotEmpty
        ? NetworkImage(profileImage)
        : const AssetImage(AppAssets.profile);

    final avatarCore = Container(
      width: avatarDiameter,
      height: avatarDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: innerBackgroundColor,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
    );

    if (!hasActiveStory) {
      debugPrint('⚪ [StoryAvatarIndicator] Rendering normal avatar');
      return avatarCore;
    }

    debugPrint(
      '🟠 [StoryAvatarIndicator] Rendering story ring style=${isViewed ? "viewed" : "active"}',
    );

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isViewed
              ? const [
                  Color(0xFF9E9E9E),
                  Color(0xFF757575),
                  Color(0xFFBDBDBD),
                ]
              : const [
                  Color(0xFFFEDA75),
                  Color(0xFFFA7E1E),
                  Color(0xFFD62976),
                  Color(0xFF962FBF),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isViewed ? Colors.grey : const Color(0xFFD62976))
                .withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
