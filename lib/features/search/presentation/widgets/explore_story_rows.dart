import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/home/presentation/widgets/story_ring_avatar.dart';
import 'package:gruve_app/features/search/domain/entities/explore_story_model.dart';

Widget _networkOrPlaceholder(
  String url, {
  required double width,
  required double height,
}) {
  if (url.isEmpty) {
    return Image.asset(
      AppAssets.profile,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: BoxFit.cover,
    placeholder: (_, _) => Container(color: Colors.white10),
    errorWidget: (_, _, _) => Image.asset(
      AppAssets.profile,
      width: width,
      height: height,
      fit: BoxFit.cover,
    ),
  );
}

/// Thin neutral outline for avatars with no active (colored) ring, so they
/// still read as round story circles.
Widget _plainRing(Widget avatar) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white38, width: 1.5),
    ),
    child: avatar,
  );
}

class ExploreSectionTitle extends StatelessWidget {
  final String title;
  const ExploreSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rw(16),
        context.rh(8),
        context.rw(16),
        context.rh(10),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.rf(17),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Friends row. First circle is always the logged-in user — an Add Story
/// circle when they have no story, otherwise their avatar (never a ring).
class FriendsStoriesRow extends StatelessWidget {
  final ExploreStory? myStory;
  final String? myAvatarUrl;
  final List<ExploreStory> friends;
  final VoidCallback onAddStory;
  final VoidCallback onMyStoryTap;
  final ValueChanged<ExploreStory> onStoryTap;

  const FriendsStoriesRow({
    super.key,
    required this.myStory,
    required this.myAvatarUrl,
    required this.friends,
    required this.onAddStory,
    required this.onMyStoryTap,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.rw(68);
    final labelWidth = size + context.rw(8);

    return SizedBox(
      height: size + context.rh(34),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
        itemCount: friends.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: context.rw(12)),
        itemBuilder: (context, index) {
          if (index == 0) {
            final hasStory = myStory != null;
            final myPicture = myStory?.user.profilePicture ?? '';
            final avatar = _plainRing(
              ClipOval(
                child: _networkOrPlaceholder(
                  myPicture.isNotEmpty ? myPicture : (myAvatarUrl ?? ''),
                  width: size,
                  height: size,
                ),
              ),
            );
            return _StoryCircle(
              width: labelWidth,
              label: hasStory ? 'My Story' : 'Add Story',
              onTap: hasStory ? onMyStoryTap : onAddStory,
              circle: Stack(
                clipBehavior: Clip.none,
                children: [
                  avatar,
                  if (!hasStory)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: context.rw(22),
                        height: context.rw(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF962FBF),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: context.rw(14),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          final story = friends[index - 1];
          return _StoryCircle(
            width: labelWidth,
            label: story.user.displayName,
            onTap: () => onStoryTap(story),
            circle: story.hasUnseenStory
                ? StoryRingAvatar(
                    hasUnseenStory: true,
                    hasCloseFriendsStory: story.hasCloseFriendsStory,
                    avatar: ClipOval(
                      child: _networkOrPlaceholder(
                        story.user.profilePicture,
                        width: size,
                        height: size,
                      ),
                    ),
                  )
                : _plainRing(
                    ClipOval(
                      child: _networkOrPlaceholder(
                        story.user.profilePicture,
                        width: size,
                        height: size,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final double width;
  final String label;
  final Widget circle;
  final VoidCallback onTap;

  const _StoryCircle({
    required this.width,
    required this.label,
    required this.circle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            circle,
            SizedBox(height: context.rh(6)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: context.rf(12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Following row — portrait cards, API order.
class FollowingStoriesRow extends StatelessWidget {
  final List<ExploreStory> stories;
  final ValueChanged<ExploreStory> onStoryTap;

  const FollowingStoriesRow({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = context.rw(112);
    final cardH = cardW * 1.65;
    final avatarSize = context.rw(30);

    return SizedBox(
      height: cardH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
        itemCount: stories.length,
        separatorBuilder: (_, _) => SizedBox(width: context.rw(8)),
        itemBuilder: (context, index) {
          final story = stories[index];
          return GestureDetector(
            onTap: () => onStoryTap(story),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkOrPlaceholder(
                      story.cardImage,
                      width: cardW,
                      height: cardH,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Color(0xB3000000), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      left: context.rw(8),
                      right: context.rw(8),
                      bottom: context.rh(8),
                      child: Row(
                        children: [
                          StoryRingAvatar(
                            hasUnseenStory: story.hasUnseenStory,
                            hasCloseFriendsStory: story.hasCloseFriendsStory,
                            ringWidth: 1.5,
                            ringGap: 1.5,
                            avatar: ClipOval(
                              child: _networkOrPlaceholder(
                                story.user.profilePicture,
                                width: avatarSize,
                                height: avatarSize,
                              ),
                            ),
                          ),
                          SizedBox(width: context.rw(6)),
                          Expanded(
                            child: Text(
                              story.user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.rf(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
