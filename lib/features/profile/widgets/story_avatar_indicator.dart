import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';

/// Reusable story avatar indicator widget
class StoryAvatarIndicator extends StatelessWidget {
  final String profileImage;
  final double radius;
  final VoidCallback? onTap;
  final bool enableNavigation;

  const StoryAvatarIndicator({
    super.key,
    required this.profileImage,
    this.radius = 50,
    this.onTap,
    this.enableNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    final storyController = StoryStateController();
    
    Widget avatar = Container(
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
        radius: radius,
        backgroundImage: profileImage.isNotEmpty
            ? NetworkImage(profileImage)
            : AssetImage(AppAssets.profile) as ImageProvider,
      ),
    );

    if (!enableNavigation) return avatar;

    return AnimatedBuilder(
      animation: storyController,
      builder: (context, _) {
        return GestureDetector(
          onTap: () {
            if (storyController.hasUserStory) {
              onTap?.call();
            }
          },
          child: Container(
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Story indicator ring
                if (storyController.hasUserStory)
                  Container(
                    width: (radius * 2) + 10,
                    height: (radius * 2) + 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE91E63),
                        width: 3,
                      ),
                    ),
                  ),
                // Profile picture
                CircleAvatar(
                  radius: radius,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : AssetImage(AppAssets.profile) as ImageProvider,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
