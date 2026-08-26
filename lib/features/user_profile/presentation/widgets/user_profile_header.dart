import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/gifts/presentation/widgets/gift_panel.dart';
import 'package:gruve_app/features/home/presentation/controller/subscribe_controller.dart';
import 'package:gruve_app/features/profile/presentation/widgets/story_avatar_indicator.dart';
import 'package:gruve_app/features/story_preview/utils/story_utils.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/gift_button.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/subscribe_button.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
    // Use unified StoryUtils navigation with userId
    // isOwnProfile: false because this is other user's profile
    AppLogger.d(
      '[UserProfileHeader] Opening other user story - isOwnProfile: false',
    );
    AppLogger.d('[UserProfileHeader] profileUserId: $profileUserId');
    StoryUtils.navigateToStoryView(
      context,
      userId: profileUserId,
      displayName: displayName,
      username: username,
      avatar: profileImageUrl ?? '',
      isOwnProfile: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(12)),
          child: Row(
            children: [
              BackButton(
                color: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
            ],
          ),
        ),
        SizedBox(height: context.rh(30)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(25)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StoryAvatarIndicator(
                profileImage: profileImageUrl ?? '',
                hasActiveStory: hasActiveStory,
                onTap: () => _openStoryView(context),
              ),
              SizedBox(width: context.rw(25)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.rh(10)),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: context.rf(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.rh(4)),
                    Text(
                      '@$username',
                      style: TextStyle(
                        color: Color(0xFF9544A7),
                        fontSize: context.rf(14),
                      ),
                    ),
                    SizedBox(height: context.rh(16)),
                    Row(
                      children: [
                        if (showSubscribeButton) ...[
                          SubscribeButton(
                            userId: profileUserId,
                            username: username,
                            subscribeController: subscribeController,
                            initialIsSubscribed: initialIsSubscribed,
                          ),
                          SizedBox(width: context.rw(8)),
                        ] else if (reserveSubscribeSpace) ...[
                          SizedBox(
                            width: context.rw(130),
                            height: context.rh(38),
                          ),
                          SizedBox(width: context.rw(8)),
                        ],
                        GiftButton(
                          onTap: () {
                            AppLogger.d("Gift Button Tapped!");
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
