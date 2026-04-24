import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/gifts/widgets/gift_panel.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/profile/widgets/story_avatar_indicator.dart';
import 'package:gruve_app/features/story_preview/screens/story_view_screen.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/gift_button.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/subscribe_button.dart';

class UserProfileHeader extends StatelessWidget {
  final String displayName;
  final String username;
  final String profileUserId;
  final String? profileImageUrl;
  final bool hasActiveStory;
  final List<String> storyMediaPaths;
  final List<DateTime> storyTimestamps;
  final bool showSubscribeButton;
  final bool reserveSubscribeSpace;
  final SubscribeController subscribeController;
  final bool initialIsSubscribed;

  const UserProfileHeader({
    super.key,
    required this.displayName,
    required this.username,
    required this.profileUserId,
    this.profileImageUrl,
    this.hasActiveStory = false,
    this.storyMediaPaths = const <String>[],
    this.storyTimestamps = const <DateTime>[],
    required this.showSubscribeButton,
    required this.subscribeController,
    this.initialIsSubscribed = false,
    this.reserveSubscribeSpace = false,
  });

  void _openStoryView(BuildContext context) {
    if (storyMediaPaths.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(
          mediaPaths: storyMediaPaths,
          username: username,
          avatarUrl: profileImageUrl,
          timestamps: storyTimestamps,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StoryAvatarIndicator(
                profileImage: profileImageUrl ?? '',
                hasActiveStory: hasActiveStory,
                onTap: () => _openStoryView(context),
              ),
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Color(0xFF9544A7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (showSubscribeButton) ...[
                          SubscribeButton(
                            userId: profileUserId,
                            username: username,
                            subscribeController: subscribeController,
                            initialIsSubscribed: initialIsSubscribed,
                          ),
                          const SizedBox(width: 21),
                        ] else if (reserveSubscribeSpace) ...[
                          const SizedBox(width: 132, height: 42),
                          const SizedBox(width: 21),
                        ],
                        GiftButton(
                          onTap: () {
                            debugPrint("Gift Button Tapped!");
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const GiftPanel(),
                            );
                          },
                        ),
                      ],
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
