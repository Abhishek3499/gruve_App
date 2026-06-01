import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../story_preview/api/create_post_api/model/post_model.dart';
import '../controllers/video_feed_controller.dart';
import 'optimized_video_overlay.dart';
import 'video_top_bar.dart';
import '../../../core/widgets/shimmer/feed_shimmer.dart';

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

class _VideoFeedState extends State<VideoFeed> {
  late VideoFeedController _controller;
  late PageController _pageController;

  String selectedContentTab = 'For You';
  int _lastPaginationTriggerItemCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = VideoFeedController();
    _pageController = PageController(viewportFraction: 1.0);

    _controller.initVideos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
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

  void _onVideoTap() {
    _controller.togglePlayPause();
  }

  void _onTabChanged(String tab) {
    setState(() {
      selectedContentTab = tab;
    });
  }

  Future<void> _refreshFeed() async {
    // Prevent multiple simultaneous refreshes
    if (_controller.isRefreshing) {
      if (kDebugMode) {
        debugPrint('⏳ [VideoFeed] Refresh already in progress, skipping');
      }
      return;
    }

    _lastPaginationTriggerItemCount = 0;
    await _controller.initVideos(refresh: true);

    if (!mounted || !_pageController.hasClients) return;

    // Only jump to top if we have new content (current index changed due to merge)
    final currentIndex = _controller.currentIndex.value;
    if (currentIndex > 0) {
      // Smooth scroll to show new content instead of jumping
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isNetworkMediaUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return false;
    }

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Widget _buildFeedItem(int index) {
    final url = _controller.mediaUrls[index].trim();
    final post = _controller.posts[index];
    final effectiveVideo = post.isVideo || Post.mediaUrlLooksLikeVideo(url);
    final isValidNetworkUrl = _isNetworkMediaUrl(url);
    final videoController = _controller.controllerForMediaIndex(index);
    final hasVideoLoadFailed = _controller.hasVideoLoadFailed(index);

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
                context: context,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _controller.currentIndex,
              builder: (context, currentIdx, _) {
                if (currentIdx != index) return const SizedBox.shrink();
                return OptimizedVideoOverlay(
                  selectedTab: selectedContentTab,
                  onTabChanged: _onTabChanged,
                  controller: _controller,
                  onOwnProfileTap: () => widget.onTabChanged(4),
                  currentIndex: currentIdx,
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
    required BuildContext context,
  }) {
    if (isVideo) {
      if (hasVideoLoadFailed) {
        if (kDebugMode) {
          debugPrint('❌ video filtered/skipped — player failed: $url');
        }
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
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
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
        ),
      );
    }

    if (!isValidNetworkUrl) {
      if (kDebugMode) {
        debugPrint('❌ image filtered/skipped — bad network URL url=$url');
      }
      return _brokenMediaIcon();
    }

    final mediaSize = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (mediaSize.width * devicePixelRatio)
        .round()
        .clamp(320, 1440)
        .toInt();
    final cacheHeight = (mediaSize.height * devicePixelRatio)
        .round()
        .clamp(640, 2560)
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

  Widget _brokenMediaIcon() {
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white, size: 50),
    );
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
                  itemBuilder: (context, index) => _buildFeedItem(index),
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
                itemBuilder: (context, index) => _buildFeedItem(index),
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
