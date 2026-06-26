import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/main.dart';

import '../../story_preview/api/create_post_api/model/post_model.dart';
import '../controllers/video_feed_controller.dart';
import 'optimized_video_overlay.dart';
import 'video_top_bar.dart';
import '../../../core/widgets/shimmer/feed_shimmer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VideoFeed extends StatefulWidget {
  final int selectedIndex;
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

  String selectedContentTab = 'For You';
  int _lastPaginationTriggerItemCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = VideoFeedController();
    _pageController = PageController(viewportFraction: 1.0);

    _controller.onScrollToTop = () {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
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
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    AppLogger.d('🚦 [VideoFeed] User navigated away - pausing video');
    _controller.pauseCurrentVideo();
  }

  @override
  void didPopNext() {
    AppLogger.d('🚦 [VideoFeed] User returned - resuming video');
    _controller.playVideo(_controller.currentIndex.value);
  }

  void _onPageChanged(int page) {
    _controller.playVideo(page);
    HapticFeedback.selectionClick();

    // Threshold-based pagination: load more when user is close to end.
    const paginationThreshold = 2;
    final remainingItems = _controller.mediaUrls.length - page - 1;
    final itemCount = _controller.mediaUrls.length;

    if (remainingItems <= paginationThreshold &&
        itemCount != _lastPaginationTriggerItemCount &&
        _controller.hasMore &&
        !_controller.isLoadingMore &&
        !_controller.isRefreshing) {
      _lastPaginationTriggerItemCount = itemCount;
      _controller.loadMorePosts();
    }
  }

  void _onTabChanged(String tab) {
    if (selectedContentTab == tab) return;

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
    return const FeedShimmer();
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
    // ✅ Split state: Only rebuild UI when feed structure changes, not on every video load
    return ValueListenableBuilder<int>(
      valueListenable: _controller.feedRevision,
      builder: (context, _, _) {
        final showInitialLoader =
            _controller.isInitialLoading && _controller.mediaUrls.isEmpty;
        final showEmptyState =
            !_controller.isInitialLoading &&
            _controller.mediaUrls.isEmpty &&
            !_controller.isRefreshing;
        final showRefreshIndicator = _controller.mediaUrls.isNotEmpty;

        return Stack(
          children: [
            if (showInitialLoader)
              _buildInitialLoader()
            else if (showEmptyState)
              _buildEmptyState()
            else if (showRefreshIndicator)
              RefreshIndicator(
                notificationPredicate: (notification) =>
                    notification.depth == 0 &&
                    _controller.currentIndex.value == 0,
                onRefresh: _refreshFeed,
                color: Colors.white,
                backgroundColor: Colors.grey[800],
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: _controller.mediaUrls.length,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemBuilder: (context, index) => FeedItemWidget(
                    index: index,
                    controller: _controller,
                    selectedTab: selectedContentTab,
                    onTabChanged: _onTabChanged,
                    onOwnProfileTap: () => widget.onTabChanged(4),
                  ),
                ),
              )
            else
              // Fallback: show feed without refresh indicator if needed
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: _controller.mediaUrls.length,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemBuilder: (context, index) => FeedItemWidget(
                  index: index,
                  controller: _controller,
                  selectedTab: selectedContentTab,
                  onTabChanged: _onTabChanged,
                  onOwnProfileTap: () => widget.onTabChanged(4),
                ),
              ),
            _buildPagingLoader(),
            VideoTopBar(
              selectedTab: selectedContentTab,
              onTabChanged: _onTabChanged,
            ),
          ],
        );
      },
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
      duration: const Duration(milliseconds: 500),
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

  Widget _brokenMediaIcon() {
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white, size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.mediaUrls[widget.index].trim();
    final post = widget.controller.posts[widget.index];
    final effectiveVideo = post.isVideo || Post.mediaUrlLooksLikeVideo(url);
    final isValidNetworkUrl = _isNetworkMediaUrl(url);
    final videoController = widget.controller.controllerForMediaIndex(widget.index);
    final hasVideoLoadFailed = widget.controller.hasVideoLoadFailed(widget.index);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: effectiveVideo ? _onVideoTap : null,
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              child: _buildMediaContent(
                url: url,
                isVideo: effectiveVideo,
                isValidNetworkUrl: isValidNetworkUrl,
                videoController: videoController,
                hasVideoLoadFailed: hasVideoLoadFailed,
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

  Widget _buildMediaContent({
    required String url,
    required bool isVideo,
    required bool isValidNetworkUrl,
    required VideoPlayerController? videoController,
    required bool hasVideoLoadFailed,
  }) {
    if (isVideo) {
      if (hasVideoLoadFailed) {
        AppLogger.d('❌ video filtered/skipped — player failed: $url');
        return _brokenMediaIcon();
      }

      if (videoController == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      if (!videoController.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      return RepaintBoundary(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoController.value.size.width,
              height: videoController.value.size.height,
              child: VideoPlayer(videoController),
            ),
          ),
        ),
      );
    }

    if (!isValidNetworkUrl) {
      AppLogger.d('❌ image filtered/skipped — bad network URL url=$url');
      return _brokenMediaIcon();
    }

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
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        useOldImageOnUrlChange: true,
        placeholder: (context, url) => Container(color: Colors.black),
        errorWidget: (context, url, error) => _brokenMediaIcon(),
      ),
    );
  }
}
