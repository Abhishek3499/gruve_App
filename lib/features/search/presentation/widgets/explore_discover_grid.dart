import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/media/grid_video_preview_manager.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/profile/presentation/screens/post_detail/profile_post_detail_screen.dart';
import 'package:gruve_app/features/search/domain/entities/explore_reel_model.dart';
import 'package:gruve_app/features/search/presentation/controller/explore_reels_controller.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:video_player/video_player.dart';

/// Two-column Discover cards as a sliver, so the screen scrolls as one list.
class ExploreDiscoverSliver extends StatelessWidget {
  final ExploreReelsController controller;

  const ExploreDiscoverSliver({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final reels = controller.reels;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        context.rw(16),
        0,
        context.rw(16),
        MediaQuery.paddingOf(context).bottom + context.rh(80),
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: context.rw(10),
          mainAxisSpacing: context.rw(10),
          childAspectRatio: 0.6,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final reel = reels[index];
          return RepaintBoundary(
            child: _DiscoverCard(
              reel: reel,
              post: controller.displayPost(reel),
              onTap: () => openExploreReel(context, controller, reel),
            ),
          );
        }, childCount: reels.length),
      ),
    );
  }
}

/// Opens a reel the same way the rest of the app opens a post from its id.
Future<void> openExploreReel(
  BuildContext context,
  ExploreReelsController controller,
  ExploreReel reel,
) async {
  final service = controller.service;
  final reels = controller.reels;
  final tappedIndex = reels.indexWhere((item) => item.id == reel.id);
  final initialIndex = tappedIndex >= 0 ? tappedIndex : 0;

  final allPosts = reels.map(service.viewerPostFor).toList();
  var post = allPosts[initialIndex];

  final resolved = await service.resolveReelForViewer(reels[initialIndex]);
  if (resolved != null) {
    post = resolved;
    allPosts[initialIndex] = resolved;
  } else if (!_hasPlayableVideo(post)) {
    final fallback = await service.resolveReelPost(reels[initialIndex]);
    if (fallback != null) {
      post = fallback;
      allPosts[initialIndex] = fallback;
    }
  }

  if (!context.mounted) return;

  if (!_hasPlayableVideo(post)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not load this reel right now')),
    );
    return;
  }

  final tappedReel = reels[initialIndex];

  await Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProfilePostDetailScreen(
          post: post,
          allPosts: allPosts,
          initialIndex: initialIndex,
          isOwnProfile: false,
          fallbackDisplayName: tappedReel.user.username,
          fallbackProfilePicture: tappedReel.user.profilePicture,
          onResolveMedia: () => service.resolveReelForViewer(tappedReel),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

bool _hasPlayableVideo(Post post) {
  final media = post.media.trim();
  return post.isVideo &&
      media.isNotEmpty &&
      (media.startsWith('http://') || media.startsWith('https://'));
}

/// "Today" / "Yesterday" / "3d ago" from the reel's created_at.
String _dayLabel(DateTime? createdAt) {
  if (createdAt == null) return '';
  final now = DateTime.now();
  final created = createdAt.toLocal();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(created.year, created.month, created.day)).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '${days}d ago';
}

class _DiscoverCard extends StatelessWidget {
  final ExploreReel reel;
  final Post post;
  final VoidCallback onTap;

  const _DiscoverCard({
    required this.reel,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = context.rw(30);
    final day = _dayLabel(reel.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white10),
            _DiscoverThumbnail(
              key: ValueKey('discover-reel-${reel.id}'),
              reel: reel,
              post: post,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: context.rw(10),
              right: context.rw(10),
              bottom: context.rh(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: reel.user.profilePicture.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: reel.user.profilePicture,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Image.asset(
                              AppAssets.profile,
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            AppAssets.profile,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                          ),
                  ),
                  SizedBox(height: context.rh(6)),
                  Text(
                    reel.user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (day.isNotEmpty)
                    Text(
                      day,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.rf(12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows thumbnail image. When ≥50% visible, auto-plays a muted HLS preview.
/// Reverts to thumbnail when scrolled away. Max 2 cards play at once.
class _DiscoverThumbnail extends StatefulWidget {
  final ExploreReel reel;
  final Post post;

  const _DiscoverThumbnail({
    super.key,
    required this.reel,
    required this.post,
  });

  @override
  State<_DiscoverThumbnail> createState() => _DiscoverThumbnailState();
}

class _DiscoverThumbnailState extends State<_DiscoverThumbnail> {
  final _manager = GridVideoPreviewManager.instance;
  String get _id => 'discover-${widget.reel.id}';
  String get _videoUrl => widget.reel.playbackUrl;
  String get _thumbUrl => widget.reel.thumbnailImageUrl;

  @override
  void initState() {
    super.initState();
    _manager.activeIds.addListener(_onActiveChanged);
  }

  @override
  void dispose() {
    _manager.activeIds.removeListener(_onActiveChanged);
    _manager.onDispose(_id);
    super.dispose();
  }

  void _onActiveChanged() {
    if (mounted) setState(() {});
  }

  bool get _isActive => _manager.activeIds.value.contains(_id);

  @override
  Widget build(BuildContext context) {
    final thumbUrl = _thumbUrl;
    final videoUrl = _videoUrl;

    return VisibilityDetector(
      key: Key(_id),
      onVisibilityChanged: (info) {
        if (videoUrl.isEmpty) return;
        _manager.onVisibilityChanged(_id, videoUrl, info.visibleFraction);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail always underneath
          if (thumbUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: thumbUrl,
              fit: BoxFit.cover,
              memCacheWidth: 480,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, _) => Shimmer.fromColors(
                baseColor: Colors.white10,
                highlightColor: Colors.white24,
                child: const ColoredBox(color: Colors.white10),
              ),
              errorWidget: (_, _, _) => const _ThumbnailPlaceholder(),
            )
          else
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: const ColoredBox(color: Colors.white10),
            ),
          // Video preview on top when active
          if (_isActive) _VideoPreviewLayer(id: _id, manager: _manager),
        ],
      ),
    );
  }
}

class _VideoPreviewLayer extends StatefulWidget {
  final String id;
  final GridVideoPreviewManager manager;

  const _VideoPreviewLayer({required this.id, required this.manager});

  @override
  State<_VideoPreviewLayer> createState() => _VideoPreviewLayerState();
}

class _VideoPreviewLayerState extends State<_VideoPreviewLayer> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.manager.controllerFor(widget.id);
    _ctrl?.addListener(_onCtrlUpdate);
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onCtrlUpdate);
    super.dispose();
  }

  void _onCtrlUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.manager.controllerFor(widget.id);
    if (ctrl == null || !ctrl.value.isInitialized) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: ctrl.value.isPlaying ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width,
            height: ctrl.value.size.height,
            child: VideoPlayer(ctrl),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  /// Debug-only failure reason, shown small under the icon.
  final String? reason;

  const _ThumbnailPlaceholder({this.reason});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white10,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: Colors.white38,
              size: 36,
            ),
            if (reason != null && reason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(
                  reason!.length > 90 ? reason!.substring(0, 90) : reason!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
