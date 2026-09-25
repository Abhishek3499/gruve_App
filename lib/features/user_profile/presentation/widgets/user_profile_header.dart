import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/gifts/presentation/widgets/gift_panel.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/profile/presentation/widgets/story_avatar_indicator.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_seen_notifier.dart';
import 'package:gruve_app/features/story_preview/utils/story_utils.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/gift_button.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/message_button.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/subscribe_button.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class UserProfileHeader extends ConsumerWidget {
  final String displayName;
  final String username;
  final String profileUserId;
  final String? profileImageUrl;
  final String bio;
  final bool hasActiveStory;
  final bool hasUnseenStory;
  final bool hasCloseFriendsStory;
  final List<String> storyMediaPaths;
  final List<DateTime> storyTimestamps;
  final bool showSubscribeButton;
  final bool reserveSubscribeSpace;
  final SubscribeNotifier subscribeController;
  final bool initialIsSubscribed;
  final bool showMessageButton;
  final VoidCallback? onMessageTap;

  const UserProfileHeader({
    super.key,
    required this.displayName,
    required this.username,
    required this.profileUserId,
    this.profileImageUrl,
    this.bio = '',
    this.hasActiveStory = false,
    this.hasUnseenStory = false,
    this.hasCloseFriendsStory = false,
    this.storyMediaPaths = const <String>[],
    this.storyTimestamps = const <DateTime>[],
    required this.showSubscribeButton,
    required this.subscribeController,
    this.initialIsSubscribed = false,
    this.reserveSubscribeSpace = false,
    this.showMessageButton = false,
    this.onMessageTap,
  });

  void _openStoryView(BuildContext context, WidgetRef ref) {
    AppLogger.d(
      '[UserProfileHeader] avatar tapped profileUserId=$profileUserId '
      'hasActiveStory=$hasActiveStory hasUnseenStory=$hasUnseenStory '
      'hasCloseFriendsStory=$hasCloseFriendsStory',
    );

    // Instagram-style: skip the network round-trip entirely when we already
    // know from the profile flags there's no story to show.
    if (!hasActiveStory) return;

    AppLogger.d(
      '[UserProfileHeader] Opening other user story - isOwnProfile: false',
    );
    StoryUtils.navigateToStoryView(
      context,
      userId: profileUserId,
      displayName: displayName,
      username: username,
      avatar: profileImageUrl ?? '',
      isOwnProfile: false,
      onStoriesViewed: () {
        ref.read(storySeenNotifierProvider.notifier).markUserSeen(profileUserId);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeenOverride = ref.watch(
      storySeenNotifierProvider.select((state) => state.isSeen(profileUserId)),
    );
    final effectiveUnseen = hasUnseenStory && !isSeenOverride;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Top Bar with Back button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(12)),
          child: Row(
            children: [
              BackButton(
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 10),

        /// Avatar + User Info Row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StoryAvatarIndicator(
                profileImage: profileImageUrl ?? '',
                hasActiveStory: hasActiveStory,
                hasUnseenStory: effectiveUnseen,
                hasCloseFriendsStory: hasCloseFriendsStory,
                showCameraIcon: false,
                onTap: () => _openStoryView(context, ref),
              ),
              SizedBox(width: context.rw(18)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : "User",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: context.rf(20),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username.startsWith('@') ? username : '@$username',
                      style: TextStyle(
                        color: const Color(0xFFBA68C8),
                        fontSize: context.rf(15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        bio.trim(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rf(13),
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
        SizedBox(height: context.rh(18)),

        /// Action Buttons: Subscribe, Message, Gift
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(20)),
          child: Row(
            children: [
              if (showSubscribeButton) ...[
                Expanded(
                  child: SubscribeButton(
                    userId: profileUserId,
                    username: username,
                    subscribeController: subscribeController,
                    initialIsSubscribed: initialIsSubscribed,
                  ),
                ),
                SizedBox(width: context.rw(10)),
              ] else if (reserveSubscribeSpace) ...[
                Expanded(
                  child: SizedBox(height: context.rh(44)),
                ),
                SizedBox(width: context.rw(10)),
              ],
              if (showMessageButton && onMessageTap != null) ...[
                Expanded(
                  child: MessageButton(onTap: onMessageTap!),
                ),
                SizedBox(width: context.rw(10)),
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
        ),
      ],
    );
  }
}
