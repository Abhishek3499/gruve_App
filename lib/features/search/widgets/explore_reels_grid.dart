import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/widgets/profile_grid_style.dart';
import 'package:gruve_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:gruve_app/core/widgets/shimmer/profile_shimmer.dart';
import 'package:gruve_app/features/profile/screens/post_detail/profile_post_detail_screen.dart';
import 'package:gruve_app/features/search/controllers/explore_reels_controller.dart';
import 'package:gruve_app/features/search/models/explore_reel_model.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';

class ExploreReelsGrid extends StatefulWidget {
  final ExploreReelsController controller;

  const ExploreReelsGrid({super.key, required this.controller});

  @override
  State<ExploreReelsGrid> createState() => _ExploreReelsGridState();
}

class _ExploreReelsGridState extends State<ExploreReelsGrid> {
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger(
    threshold: 320,
  );
  int _lastPrefetchedReelCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _scrollController.addListener(_onScroll);
    if (widget.controller.reels.isNotEmpty) {
      _lastPrefetchedReelCount = widget.controller.reels.length;
      _warmupReelAssets(widget.controller.reels, fromIndex: 0);
    }
  }

  @override
  void didUpdateWidget(covariant ExploreReelsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final count = widget.controller.reels.length;
    if (count > _lastPrefetchedReelCount) {
      final fromIndex = _lastPrefetchedReelCount;
      _lastPrefetchedReelCount = count;
      _warmupReelAssets(widget.controller.reels, fromIndex: fromIndex);
    }
    setState(() {});
  }

  void _warmupReelAssets(List<ExploreReel> reels, {required int fromIndex}) {
    if (!mounted || fromIndex >= reels.length) return;

    final slice = reels.skip(fromIndex).toList();
    final posts = slice.map(widget.controller.displayPost).toList();
    PostGridThumbnail.warmupPosts(posts, max: posts.length);

    final videoUrls = slice
        .map((reel) => reel.displayMediaUrl)
        .where((url) => url.isNotEmpty)
        .toSet();
    if (videoUrls.isNotEmpty) {
      unawaited(VideoFrameCache.warmupMany(videoUrls, concurrency: 8));
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final controller = widget.controller;
    if (_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: controller.isLoading || controller.isLoadingMore,
      hasMore: controller.hasMore,
    )) {
      controller.loadMore(reason: 'scroll');
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.isLoading && controller.reels.isEmpty) {
      return const ExploreGridShimmer();
    }

    if (controller.error != null && controller.reels.isEmpty) {
      return _buildErrorState(controller.error!);
    }

    if (controller.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.loaderDark,
      backgroundColor: Colors.white24,
      onRefresh: controller.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        cacheExtent: 900,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSortChips(controller)),
          SliverPadding(
            padding: ProfileGridStyle.gridPadding,
            sliver: SliverGrid(
              gridDelegate: ProfileGridStyle.gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final reel = controller.reels[index];
                  return RepaintBoundary(
                    child: _ExploreReelTile(
                      reel: reel,
                      post: controller.displayPost(reel),
                      onTap: () => _openReel(context, reel),
                    ),
                  );
                },
                childCount: controller.reels.length,
              ),
            ),
          ),
          if (controller.isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ProfileGridStyle.gridPadding.left,
                  8,
                  ProfileGridStyle.gridPadding.right,
                  8,
                ),
                child: const AppShimmer(
                  child: ShimmerBox(
                    height: 120,
                    width: double.infinity,
                    borderRadius: ProfileGridStyle.tileRadius,
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSortChips(ExploreReelsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          _SortChip(
            label: 'Trending',
            selected: controller.sort == 'trending',
            onTap: () => controller.changeSort('trending'),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Latest',
            selected: controller.sort == 'latest',
            onTap: () => controller.changeSort('latest'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.controller.refresh,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No reels to explore yet',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }

  Future<void> _openReel(BuildContext context, ExploreReel reel) async {
    final controller = widget.controller;
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
}

/// Explore reels often ship only `.mp4` URLs (no JPEG poster). Prefer the
/// resolved reel media URL so video-first-frame thumbnails always have a source.
class _ExploreReelThumbnail extends StatelessWidget {
  final ExploreReel reel;
  final Post post;

  const _ExploreReelThumbnail({
    super.key,
    required this.reel,
    required this.post,
  });

  String get _mediaUrl {
    final fromPost = post.media.trim();
    if (fromPost.isNotEmpty) return fromPost;
    return reel.displayMediaUrl;
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = _mediaUrl;
    final imagePoster = post.gridPreviewUrl.trim();

    if (imagePoster.isNotEmpty &&
        !Post.mediaUrlLooksLikeVideo(imagePoster)) {
      return MediaUrlThumbnail(url: imagePoster);
    }

    if (mediaUrl.isNotEmpty) {
      return MediaUrlThumbnail(url: mediaUrl);
    }

    return PostGridThumbnail(post: post);
  }
}

class _ExploreReelTile extends StatelessWidget {
  final ExploreReel reel;
  final Post post;
  final VoidCallback onTap;

  const _ExploreReelTile({
    required this.reel,
    required this.post,
    required this.onTap,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      final double val = count / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (count >= 1000) {
      final double val = count / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final int displayCount = reel.likes;

    return GestureDetector(
      onTap: onTap,
      child: ProfileGridTile(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ExploreReelThumbnail(
              key: ValueKey('explore-reel-${reel.id}'),
              reel: reel,
              post: post,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            if (displayCount > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(displayCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
