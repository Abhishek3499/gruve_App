import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/gifts/presentation/widgets/gift_panel.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/profile/presentation/widgets/stats_row.dart';
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
  final String followStatus;
  final String? action;
  final bool isPrivate;
  final bool showMessageButton;
  final VoidCallback? onMessageTap;
  final VoidCallback? onFollowRequestHandled;
  // Stats (same as own profile StatsRow)
  final int subscribersCount;
  final int likesCount;
  final int videosCount;
  final VoidCallback? onSubscribersTap;
  final VoidCallback? onSubscribedTap;

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
    this.followStatus = 'none',
    this.action,
    this.isPrivate = false,
    this.reserveSubscribeSpace = false,
    this.showMessageButton = false,
    this.onMessageTap,
    this.onFollowRequestHandled,
    this.subscribersCount = 0,
    this.likesCount = 0,
    this.videosCount = 0,
    this.onSubscribersTap,
    this.onSubscribedTap,
  });

  String _formatUsername(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '@username';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  void _openStoryView(BuildContext context, WidgetRef ref) {
    AppLogger.d(
      '[UserProfileHeader] avatar tapped profileUserId=$profileUserId '
      'hasActiveStory=$hasActiveStory',
    );
    if (!hasActiveStory) return;
    StoryUtils.navigateToStoryView(
      context,
      userId: profileUserId,
      displayName: displayName,
      username: username,
      avatar: profileImageUrl ?? '',
      isOwnProfile: false,
      onStoriesViewed: () {
        ref
            .read(storySeenNotifierProvider.notifier)
            .markUserSeen(profileUserId);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeenOverride = ref.watch(
      storySeenNotifierProvider.select((state) => state.isSeen(profileUserId)),
    );
    final effectiveUnseen = hasUnseenStory && !isSeenOverride;
    final displayUsername = _formatUsername(username);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Top Bar: [back] on left, [@username] centered, [options] on right
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              /// Back button (Left)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              /// Username centered
              Expanded(
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

              /// Options icon (Right) — placeholder for symmetry
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {},
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
              StoryAvatarIndicator(
                profileImage: profileImageUrl ?? '',
                radius: 36,
                ringWidth: 2.0,
                ringGap: 2.0,
                hasActiveStory: hasActiveStory,
                hasUnseenStory: effectiveUnseen,
                hasCloseFriendsStory: hasCloseFriendsStory,
                showCameraIcon: false,
                onTap: () => _openStoryView(context, ref),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 1),
                      child: Text(
                        displayName.isNotEmpty ? displayName : 'User',
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

        /// Bio section
        if (bio.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _UserBioView(bio: bio),
          ),
        ],

        SizedBox(height: context.rh(12)),

        /// Action Buttons: Subscribe, Message, Gift
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showSubscribeButton) ...[
                Expanded(
                  child: SubscribeButton(
                    userId: profileUserId,
                    username: username,
                    subscribeController: subscribeController,
                    initialIsSubscribed: initialIsSubscribed,
                    followStatus: followStatus,
                    action: action,
                    isPrivate: isPrivate,
                    onFollowRequestHandled: onFollowRequestHandled,
                  ),
                ),
                SizedBox(width: context.rw(10)),
              ] else if (reserveSubscribeSpace) ...[
                Expanded(child: SizedBox(height: context.rh(44))),
                SizedBox(width: context.rw(10)),
              ],
              if (showMessageButton && onMessageTap != null) ...[
                Expanded(child: MessageButton(onTap: onMessageTap!)),
                SizedBox(width: context.rw(10)),
              ],
              GiftButton(
                onTap: () {
                  AppLogger.d('Gift Button Tapped!');
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

class _UserBioView extends StatefulWidget {
  final String bio;
  const _UserBioView({required this.bio});

  @override
  State<_UserBioView> createState() => _UserBioViewState();
}

class _UserBioViewState extends State<_UserBioView> {
  bool _isExpanded = false;
  static const int _previewLength = 40;

  @override
  Widget build(BuildContext context) {
    final cleanBio = widget.bio.trim();
    if (cleanBio.isEmpty) return const SizedBox.shrink();

    const baseStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      height: 20.0 / 14.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );
    const moreStyle = TextStyle(
      color: Color(0xFFFF3AFF),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    final needsTruncation = cleanBio.length > _previewLength;

    if (!needsTruncation) {
      return Text(cleanBio, style: baseStyle);
    }

    if (_isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = false),
        child: RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: cleanBio),
              const TextSpan(text: '  '),
              TextSpan(text: 'less', style: moreStyle),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: cleanBio.substring(0, _previewLength)),
            TextSpan(text: '... more', style: moreStyle),
          ],
        ),
      ),
    );
  }
}
