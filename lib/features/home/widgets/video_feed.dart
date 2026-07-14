import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/main.dart';
import 'package:shimmer/shimmer.dart';

import '../../story_preview/api/create_post_api/model/post_model.dart';
import '../controllers/video_feed_controller.dart';
import 'optimized_video_overlay.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'video_top_bar.dart';
import '../../../core/widgets/shimmer/feed_shimmer.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VideoFeed extends StatefulWidget {
  final ValueNotifier<int> selectedIndex;
  final Function(int) onTabChanged;
  final Function(VideoFeedController)? onControllerReady;

  const VideoFeed({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.onControllerReady,
  });

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> with RouteAware {
  late VideoFeedController _controller;
  late PageController _pageController;
  VoidCallback? _blockListener;

  String selectedContentTab = 'For You';
  int _lastPaginationTriggerItemCount = 0;
  String? _lastSurfacedLoadError;
  late final VoidCallback _loadErrorListener;

  @override
  void initState() {
    super.initState();

    _controller = VideoFeedController();
    _loadErrorListener = _surfaceNonBlockingLoadError;
    _controller.loadErrorListenable.addListener(_loadErrorListener);

    // Set isBlockedUser callback to filter blocked users on load/pagination
    final blockProvider = context.read<BlockProvider>();
    _controller.isBlockedUser = (userId) => blockProvider.isBlocked(userId);

    // Listen to BlockProvider for immediate feed removal of blocked users
    _blockListener = () {
      if (!mounted) return;
      final blockedUserIds = _controller.posts
          .map((post) => post.userId)
          .where((userId) => blockProvider.isBlocked(userId))
          .toSet();
      if (blockedUserIds.isNotEmpty) {
        AppLogger.d('🔒 [VideoFeed] Blocked users detected in feed, removing: $blockedUserIds');
        _controller.removePostsByUsers(blockedUserIds);
      }
    };
    blockProvider.addListener(_blockListener!);

    _pageController = PageController(viewportFraction: 1.0);

    _controller.onScrollToTop = () {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    };

    _controller.onPostsRemoved = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        if (_controller.mediaUrls.isEmpty) return;
        final target = _controller.currentIndex.value
            .clamp(0, _controller.mediaUrls.length - 1);
        final currentPage = _pageController.page?.round();
        if (currentPage != target) {
          _pageController.jumpToPage(target);
        }
      });
    };

    _controller.initVideos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
      if (mounted) {
        final savePostProvider = context.read<SavePostProvider>();
        if (savePostProvider.savedPosts.isEmpty || savePostProvider.isSavedPostsStale) {
          savePostProvider.fetchSavedPosts();
        }
        final route = ModalRoute.of(context);
        if (route is PageRoute) {
          routeObserver.subscribe(this, route);
        }
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (_blockListener != null) {
      try {
        context.read<BlockProvider>().removeListener(_blockListener!);
      } catch (e) {
        AppLogger.d('⚠️ Error removing block listener: $e');
      }
    }
    _controller.loadErrorListenable.removeListener(_loadErrorListener);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _surfaceNonBlockingLoadError() {
    final error = _controller.loadErrorListenable.value;
    if (!mounted) return;

    if (error == null) {
      _lastSurfacedLoadError = null;
      return;
    }

    if (_controller.mediaUrls.isEmpty || error == _lastSurfacedLoadError) {
      return;
    }

    _lastSurfacedLoadError = error;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.loadErrorListenable.value != error) return;
      if (_controller.mediaUrls.isEmpty) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF424242),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void didPushNext() {
    AppLogger.d('🚦 [VideoFeed] User navigated away - releasing video controllers to free decoders');
    _controller.releaseAllControllers();
  }

  @override
  void didPopNext() {
    AppLogger.d('🚦 [VideoFeed] User returned - didPopNext triggered');
    if (widget.selectedIndex.value == 0) {
      AppLogger.d('🚦 [VideoFeed] Currently on Home tab, resuming video');
      _controller.playVideo(_controller.currentIndex.value);
    } else {
      AppLogger.d('🚦 [VideoFeed] Not on Home tab (selectedIndex: ${widget.selectedIndex.value}), keeping video paused');
    }
  }

  void _onPageChanged(int page) {
    AppLogger.d('📄 [VideoFeed] onPageChanged page=$page');
    _controller.playVideo(page, deferPreload: true);
    _controller.warmupVideoAt(page + 1);
    HapticFeedback.selectionClick();
    unawaited(_maybeLoadMorePages(page));
  }

  void _onFeedScroll(ScrollNotification notification) {
    if (!_pageController.hasClients) return;

    if (notification is ScrollUpdateNotification && notification.depth == 0) {
      final page = _pageController.page;
      if (page == null) return;

      final nextIndex = page.ceil();
      if (nextIndex > page && nextIndex < _controller.mediaUrls.length) {
        _controller.warmupVideoAt(nextIndex);
      }
      return;
    }

    if (notification is ScrollEndNotification && notification.depth == 0) {
      _controller.commitPendingEnsureControllersAroundIndex();
    }
  }

  /// Loads the next page when the user is near the end of the feed.
  /// The pagination latch is updated only after posts are actually appended so
  /// failed or skipped requests can retry on the next scroll event.
  Future<void> _maybeLoadMorePages(int page) async {
    const paginationThreshold = 2;
    final remainingItems = _controller.mediaUrls.length - page - 1;
    final itemCount = _controller.mediaUrls.length;

    if (remainingItems > paginationThreshold ||
        itemCount == _lastPaginationTriggerItemCount ||
        !_controller.hasMore ||
        _controller.isLoadingMore ||
        _controller.isRefreshing) {
      return;
    }

    final countBefore = _controller.mediaUrls.length;
    final result = await _controller.loadMorePosts(reason: 'scroll');
    if (!mounted) return;

    final postsAppended = _controller.mediaUrls.length > countBefore;
    if (result == true && postsAppended) {
      _lastPaginationTriggerItemCount = countBefore;
    }
  }

  void _onTabChanged(String tab) {
    if (selectedContentTab == tab) return;

    _lastSurfacedLoadError = null;

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    _controller.changeFeed(tab);

    setState(() {
      selectedContentTab = tab;
    });

    _controller.initVideos();
  }

  Future<void> _refreshFeed() async {
    // Prevent multiple simultaneous refreshes
    if (_controller.isRefreshing) {
      AppLogger.d('⏳ [VideoFeed] Refresh already in progress, skipping');
      
      return;
    }

    _lastPaginationTriggerItemCount = 0;
    await _controller.initVideos(refresh: true);

    if (!mounted || !_pageController.hasClients) return;

    // Jump to top directly to ensure UI and controller state are instantly in sync
    final currentIndex = _controller.currentIndex.value;
    if (currentIndex > 0) {
      _pageController.jumpToPage(0);
    }
  }



  Widget _buildInitialLoader() {
    // ✅ PRODUCTION SHIMMER — shows exact layout of what's loading
    // Users immediately understand the structure instead of staring at a spinner
    return const FeedShimmerLoader();
  }

  Widget _buildEmptyState() {
    final hasError = _controller.loadError != null;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError
                    ? Icons.wifi_off_rounded
                    : Icons.video_library_outlined,
                color: Colors.white70,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                hasError ? _controller.loadError! : 'No posts yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: _refreshFeed, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagingLoader() {
    if (!_controller.isLoadingMore) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 96,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedPresentationListenable = Listenable.merge([
      _controller.isInitialFeedLoadingListenable,
      _controller.feedStructureRevision,
    ]);

    return Stack(
      children: [
        ListenableBuilder(
          listenable: feedPresentationListenable,
          builder: (context, _) {
            final showInitialLoader = _controller.isInitialFeedLoading;
            final showEmptyState =
                !_controller.isInitialFeedLoading &&
                _controller.mediaUrls.isEmpty &&
                !_controller.isRefreshing;

            if (showInitialLoader) return _buildInitialLoader();
            if (showEmptyState) return _buildEmptyState();
            return const SizedBox.shrink();
          },
        ),
        ListenableBuilder(
          listenable: feedPresentationListenable,
          builder: (context, pageViewHost) {
            if (_controller.isInitialFeedLoading ||
                _controller.mediaUrls.isEmpty) {
              return const SizedBox.shrink();
            }
            return pageViewHost!;
          },
          child: ValueListenableBuilder<int>(
            valueListenable: _controller.feedStructureRevision,
            builder: (context, revision, _) {
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _onFeedScroll(notification);
                  return false;
                },
                child: RefreshIndicator(
                  notificationPredicate: (notification) =>
                      notification.depth == 0 &&
                      _controller.currentIndex.value == 0,
                  onRefresh: _refreshFeed,
                  color: Colors.white,
                  backgroundColor: Colors.grey[800],
                  child: PageView.builder(
                    key: ValueKey(_controller.currentFeed),
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    allowImplicitScrolling: true,
                    onPageChanged: _onPageChanged,
                    itemCount: _controller.mediaUrls.length,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: PageScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final post = _controller.posts[index];
                      final url = _controller.mediaUrls[index].trim();
                      return FeedItemWidget(
                        key: ValueKey(
                          post.id.isNotEmpty ? 'feed_${post.id}' : 'feed_$url',
                        ),
                        index: index,
                        controller: _controller,
                        selectedTab: selectedContentTab,
                        onTabChanged: _onTabChanged,
                        onOwnProfileTap: () => widget.onTabChanged(4),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoadingMoreListenable,
          builder: (context, isLoadingMore, child) => _buildPagingLoader(),
        ),
        VideoTopBar(
          selectedTab: selectedContentTab,
          onTabChanged: _onTabChanged,
        ),
      ],
    );
  }
}

class PlayPauseAnimationOverlay extends StatefulWidget {
  final bool isPlaying;

  const PlayPauseAnimationOverlay({super.key, required this.isPlaying});

  @override
  State<PlayPauseAnimationOverlay> createState() => _PlayPauseAnimationOverlayState();
}

class _PlayPauseAnimationOverlayState extends State<PlayPauseAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.9).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 0.9),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_animController);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FeedItemWidget extends StatefulWidget {
  final int index;
  final VideoFeedController controller;
  final String selectedTab;
  final Function(String) onTabChanged;
  final VoidCallback onOwnProfileTap;

  const FeedItemWidget({
    super.key,
    required this.index,
    required this.controller,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onOwnProfileTap,
  });

  @override
  State<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends State<FeedItemWidget> {
  bool _isPausedByUser = false;
  bool _overlayIsPlayingIcon = false;
  int _overlayTriggerCounter = 0;

  void _onVideoTap() {
    widget.controller.togglePlayPause();
    final videoController = widget.controller.controllerForMediaIndex(widget.index);
    final isPlaying = videoController?.value.isPlaying ?? false;
    setState(() {
      _isPausedByUser = !isPlaying;
      _overlayIsPlayingIcon = isPlaying;
      _overlayTriggerCounter++;
    });
  }

  bool _isNetworkMediaUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index >= widget.controller.posts.length ||
        widget.index >= widget.controller.mediaUrls.length) {
      return const SizedBox.shrink();
    }

    final post = widget.controller.posts[widget.index];
    final itemKey = post.id.isNotEmpty
        ? post.id
        : widget.controller.mediaUrls[widget.index].trim();

    return ValueListenableBuilder<int>(
      valueListenable: widget.controller.itemRevisionListenable(itemKey),
      builder: (context, _, __) => _buildFeedItem(),
    );
  }

  Widget _buildFeedItem() {
    final url = widget.controller.mediaUrls[widget.index].trim();
    final post = widget.controller.posts[widget.index];
    final effectiveVideo = post.isVideo || Post.mediaUrlLooksLikeVideo(url);
    final isValidNetworkUrl = _isNetworkMediaUrl(url);
    final videoController = widget.controller.controllerForMediaIndex(widget.index);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: effectiveVideo ? _onVideoTap : null,
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              child: FeedMediaContent(
                index: widget.index,
                controller: widget.controller,
                url: url,
                posterUrl: post.feedPosterUrl,
                isVideo: effectiveVideo,
                isValidNetworkUrl: isValidNetworkUrl,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: widget.controller.currentIndex,
              builder: (context, currentIdx, _) {
                if (currentIdx != widget.index) return const SizedBox.shrink();
                return Stack(
                  children: [
                    OptimizedVideoOverlay(
                      selectedTab: widget.selectedTab,
                      onTabChanged: widget.onTabChanged,
                      controller: widget.controller,
                      onOwnProfileTap: widget.onOwnProfileTap,
                      currentIndex: currentIdx,
                    ),
                    if (effectiveVideo && _overlayTriggerCounter > 0)
                      PlayPauseAnimationOverlay(
                        key: ValueKey(_overlayTriggerCounter),
                        isPlaying: _overlayIsPlayingIcon,
                      ),
                    if (_isPausedByUser && effectiveVideo && videoController != null)
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: videoController,
                        builder: (context, value, child) {
                          if (!value.isInitialized || value.isPlaying) {
                            return const SizedBox.shrink();
                          }
                          return IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FeedPosterShimmer extends StatelessWidget {
  const FeedPosterShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
      ),
    );
  }
}

/// Instant poster frame for feed videos — no fade, sized for device memory.
class FeedPosterImage extends StatelessWidget {
  final String url;

  const FeedPosterImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (mediaSize.width * devicePixelRatio * 0.8)
        .round()
        .clamp(320, 1080)
        .toInt();
    final cacheHeight = (mediaSize.height * devicePixelRatio * 0.8)
        .round()
        .clamp(640, 1920)
        .toInt();

    return RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        maxWidthDiskCache: cacheWidth,
        maxHeightDiskCache: cacheHeight,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (context, url) => const FeedPosterShimmer(),
        errorWidget: (context, url, error) => const ColoredBox(color: Colors.black),
      ),
    );
  }
}

/// Shows a prefetched first video frame while the feed player initializes.
class FeedCachedVideoPoster extends StatefulWidget {
  final String videoUrl;

  const FeedCachedVideoPoster({super.key, required this.videoUrl});

  @override
  State<FeedCachedVideoPoster> createState() => _FeedCachedVideoPosterState();
}

class _FeedCachedVideoPosterState extends State<FeedCachedVideoPoster> {
  VideoPlayerController? _controller;
  bool _disposed = false;
  late String _boundUrl;

  @override
  void initState() {
    super.initState();
    _boundUrl = widget.videoUrl.trim();
    final cached = VideoFrameCache.peekReady(_boundUrl);
    if (cached != null) {
      _controller = cached;
      unawaited(_attach());
    } else {
      unawaited(_load());
    }
  }

  Future<void> _attach() async {
    final controller = await VideoFrameCache.acquire(_boundUrl);
    if (!mounted || _disposed) {
      if (controller != null) VideoFrameCache.release(_boundUrl);
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _load() async {
    final controller = await VideoFrameCache.acquire(_boundUrl);
    if (!mounted || _disposed) {
      if (controller != null) VideoFrameCache.release(_boundUrl);
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void didUpdateWidget(covariant FeedCachedVideoPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl.trim() != widget.videoUrl.trim()) {
      if (_controller != null) VideoFrameCache.release(_boundUrl);
      _boundUrl = widget.videoUrl.trim();
      _controller = VideoFrameCache.peekReady(_boundUrl);
      if (_controller != null) {
        unawaited(_attach());
      } else {
        unawaited(_load());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    VideoFrameCache.release(_boundUrl);
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null &&
        controller.value.isInitialized &&
        controller.value.size.width > 0 &&
        controller.value.size.height > 0;

    if (!ready) {
      return const FeedPosterShimmer();
    }

    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class FeedMediaContent extends StatelessWidget {
  final int index;
  final VideoFeedController controller;
  final String url;
  final String posterUrl;
  final bool isVideo;
  final bool isValidNetworkUrl;

  const FeedMediaContent({
    super.key,
    required this.index,
    required this.controller,
    required this.url,
    this.posterUrl = '',
    required this.isVideo,
    required this.isValidNetworkUrl,
  });

  Widget _brokenMediaIcon() {
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white, size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isVideo) {
      return _buildImage(context);
    }

    return FeedVideoPlayer(
      index: index,
      controller: controller,
      url: url,
      posterUrl: posterUrl,
    );
  }

  Widget _buildImage(BuildContext context) {
    if (!isValidNetworkUrl) {
      AppLogger.d('❌ image filtered/skipped — bad network URL url=$url');
      return _brokenMediaIcon();
    }

    return FeedPosterImage(url: url);
  }
}

/// Keeps a stable [VideoPlayer] instance so the texture is not torn down
/// every time a neighboring slot finishes loading.
class FeedVideoPlayer extends StatefulWidget {
  final int index;
  final VideoFeedController controller;
  final String url;
  final String posterUrl;

  const FeedVideoPlayer({
    super.key,
    required this.index,
    required this.controller,
    required this.url,
    this.posterUrl = '',
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _boundController;
  bool _initialized = false;
  /// Sticky — once the first frame is shown, never fall back to shimmer on
  /// transient buffering or decoder surface recovery (Exynos freeAllBuffers).
  bool _hasEverRenderedFrame = false;
  bool _showPlaybackBufferSpinner = false;
  Timer? _bufferingShowTimer;

  static const Duration _bufferingSpinnerShowDelay = Duration(milliseconds: 400);

  bool get _isCurrentItem =>
      widget.controller.currentIndex.value == widget.index;

  bool _hasVisibleFrame(VideoPlayerValue value) {
    return value.isInitialized &&
        value.size.width > 0 &&
        value.size.height > 0;
  }

  void _cancelBufferingShowTimer() {
    _bufferingShowTimer?.cancel();
    _bufferingShowTimer = null;
  }

  void _syncPlaybackBufferSpinner(VideoPlayerValue value) {
    if (!_isCurrentItem || widget.controller.isInitialFeedLoading) {
      _cancelBufferingShowTimer();
      if (_showPlaybackBufferSpinner) {
        setState(() => _showPlaybackBufferSpinner = false);
      }
      return;
    }

    final awaitingFirstFrame =
        !value.isInitialized || !_hasEverRenderedFrame;
    if (awaitingFirstFrame) {
      _cancelBufferingShowTimer();
      if (_showPlaybackBufferSpinner) {
        setState(() => _showPlaybackBufferSpinner = false);
      }
      return;
    }

    if (value.isBuffering) {
      if (_showPlaybackBufferSpinner || (_bufferingShowTimer?.isActive ?? false)) {
        return;
      }
      _bufferingShowTimer = Timer(_bufferingSpinnerShowDelay, () {
        _bufferingShowTimer = null;
        if (!mounted) return;
        final ctrl = _boundController;
        if (ctrl == null || !_isCurrentItem) return;
        final latest = ctrl.value;
        if (!latest.isBuffering) return;
        if (!latest.isInitialized || !_hasEverRenderedFrame) return;
        setState(() => _showPlaybackBufferSpinner = true);
      });
      return;
    }

    _cancelBufferingShowTimer();
    if (_showPlaybackBufferSpinner) {
      setState(() => _showPlaybackBufferSpinner = false);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.videoControllersRevision.addListener(_syncController);
    widget.controller.currentIndex.addListener(_onCurrentIndexChanged);
    _syncController();
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _detachController();
      _syncController();
    }
  }

  @override
  void dispose() {
    widget.controller.videoControllersRevision.removeListener(_syncController);
    widget.controller.currentIndex.removeListener(_onCurrentIndexChanged);
    _cancelBufferingShowTimer();
    _detachController();
    super.dispose();
  }

  void _onCurrentIndexChanged() {
    if (widget.controller.currentIndex.value != widget.index) {
      _cancelBufferingShowTimer();
      if (_showPlaybackBufferSpinner) {
        setState(() => _showPlaybackBufferSpinner = false);
      }
      return;
    }

    final ctrl = _boundController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (!ctrl.value.isPlaying) {
      unawaited(ctrl.play());
    }

    _syncPlaybackBufferSpinner(ctrl.value);

    // Recover from a stale black texture after swiping onto a preloaded slot.
    if (mounted) setState(() {});
  }

  void _detachController() {
    _cancelBufferingShowTimer();
    _showPlaybackBufferSpinner = false;
    _boundController?.removeListener(_onControllerUpdate);
    _boundController = null;
    _initialized = false;
    _hasEverRenderedFrame = false;
  }

  void _syncController() {
    if (widget.controller.hasVideoLoadFailed(widget.index)) {
      if (_boundController != null) {
        _detachController();
        setState(() {});
      }
      return;
    }

    final next = widget.controller.controllerForMediaIndex(widget.index);
    if (identical(next, _boundController)) return;

    _boundController?.removeListener(_onControllerUpdate);
    _boundController = next;
    _initialized = next?.value.isInitialized ?? false;
    if (next != null && _hasVisibleFrame(next.value)) {
      _hasEverRenderedFrame = true;
    }
    _boundController?.addListener(_onControllerUpdate);
    if (next != null) {
      _syncPlaybackBufferSpinner(next.value);
    }
    setState(() {});
  }

  void _onControllerUpdate() {
    final ctrl = _boundController;
    if (ctrl == null) return;

    final nowInitialized = ctrl.value.isInitialized;
    final nowHasFrame = _hasVisibleFrame(ctrl.value);
    _syncPlaybackBufferSpinner(ctrl.value);
    final gainedFirstFrame = nowHasFrame && !_hasEverRenderedFrame;
    if (gainedFirstFrame) {
      _hasEverRenderedFrame = true;
    }
    if (nowInitialized != _initialized || gainedFirstFrame) {
      _initialized = nowInitialized;
      setState(() {});
    }
  }

  Widget _buildPoster(BuildContext context, {bool allowShimmer = true}) {
    final poster = widget.posterUrl.trim();
    if (poster.isNotEmpty &&
        poster.startsWith('http') &&
        !Post.mediaUrlLooksLikeVideo(poster)) {
      return FeedPosterImage(url: poster);
    }

    return allowShimmer ? const FeedPosterShimmer() : const SizedBox.shrink();
  }

  bool get _awaitingFirstFrame {
    if (!_isCurrentItem || widget.controller.isInitialFeedLoading) {
      return false;
    }
    return !widget.controller.hasVideoLoadFailed(widget.index) &&
        (widget.controller.isVideoInitializing(widget.index) ||
            !_hasEverRenderedFrame);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.controller.videoControllersRevision,
      builder: (context, _, child) => _buildVideoContent(context),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    if (widget.controller.hasVideoLoadFailed(widget.index)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPoster(context, allowShimmer: true),
          Center(
            child: GestureDetector(
              onTap: widget.controller.togglePlayPause,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tap to retry',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final videoController = _boundController;
    final showVideo = videoController != null && _initialized;
    final hidePoster = showVideo && _hasEverRenderedFrame;

    if (!showVideo) {
      // TikTok-style: poster thumbnail or shimmer only — no text, no double loader.
      return _buildPoster(context, allowShimmer: _awaitingFirstFrame);
    }

    final size = videoController.value.size;
    final frameWidth = size.width > 0 ? size.width : 1080.0;
    final frameHeight = size.height > 0 ? size.height : 1920.0;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPoster(context, allowShimmer: false),
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: VideoPlayer(
                  videoController,
                  key: ValueKey('video_player_${widget.url}'),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: hidePoster ? 0 : 1,
              duration: _isCurrentItem
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: _buildPoster(
                context,
                allowShimmer: _awaitingFirstFrame,
              ),
            ),
          ),
          if (_isCurrentItem &&
              _hasEverRenderedFrame &&
              _showPlaybackBufferSpinner)
            const VideoBufferSpinner(),
        ],
      ),
    );
  }
}

class VideoBufferSpinner extends StatelessWidget {
  const VideoBufferSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(16),
        child: const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class FeedShimmerLoader extends StatelessWidget {
  const FeedShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeedShimmer();
  }
}

