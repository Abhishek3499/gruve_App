import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/save_post_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/post_view_notifier.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/main.dart';
import 'package:shimmer/shimmer.dart';

import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/post_like_notifier.dart';
import 'package:gruve_app/features/home/presentation/controllers/video_feed_controller.dart';
import 'package:gruve_app/features/home/presentation/widgets/optimized_video_overlay.dart';
import 'package:gruve_app/features/home/presentation/widgets/double_tap_heart_overlay.dart';
import 'package:gruve_app/features/user_profile/presentation/notifiers/block_notifier.dart';
import 'package:gruve_app/features/home/presentation/widgets/video_top_bar.dart';
import 'package:gruve_app/features/home/presentation/widgets/shimmer/feed_shimmer.dart';
import 'package:gruve_app/features/comments/presentation/widgets/comment_sheet.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VideoFeed extends ConsumerStatefulWidget {
  final ValueNotifier<int> selectedIndex;
  final Function(int) onTabChanged;
  final Function(VideoFeedController)? onControllerReady;
  final VoidCallback? onInitialFeedReady;

  const VideoFeed({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.onControllerReady,
    this.onInitialFeedReady,
  });

  @override
  ConsumerState<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends ConsumerState<VideoFeed> with RouteAware {
  late VideoFeedController _controller;
  late PageController _pageController;
  ProviderSubscription<BlockState>? _blockSubscription;

  String selectedContentTab = 'For You';
  int _lastPaginationTriggerItemCount = 0;
  String? _lastSurfacedLoadError;
  late final VoidCallback _loadErrorListener;
  double _horizontalDragDistance = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = VideoFeedController();
    _loadErrorListener = _surfaceNonBlockingLoadError;
    _controller.loadErrorListenable.addListener(_loadErrorListener);

    // Set isBlockedUser callback to filter blocked users on load/pagination
    final blockNotifier = ref.read(blockNotifierProvider.notifier);
    _controller.isBlockedUser = (userId) => blockNotifier.isBlocked(userId);

    // Listen to BlockNotifier for immediate feed removal of blocked users
    _blockSubscription = ref.listenManual(blockNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final blockedUserIds = _controller.posts
          .map((post) => post.userId)
          .where((userId) => next.isBlocked(userId))
          .toSet();
      if (blockedUserIds.isNotEmpty) {
        _controller.removePostsByUsers(blockedUserIds);
      }
    });

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
        final target = _controller.currentIndex.value.clamp(
          0,
          _controller.mediaUrls.length - 1,
        );
        final currentPage = _pageController.page?.round();
        if (currentPage != target) {
          _pageController.jumpToPage(target);
        }
      });
    };

    // Fires the main feed request immediately; secondary module fetches
    // (saved posts, profile/highlights via onInitialFeedReady) are only
    // triggered once this settles, so get-post always wins the network race
    // on cold start instead of competing with them.
    unawaited(
      _controller.initVideos().then((_) {
        if (!mounted) return;
        final savePostNotifier = ref.read(savePostNotifierProvider.notifier);
        if (savePostNotifier.savedPosts.isEmpty ||
            savePostNotifier.isSavedPostsStale) {
          savePostNotifier.fetchSavedPosts();
        }
        widget.onInitialFeedReady?.call();
      }),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
      if (mounted) {
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
    _blockSubscription?.close();
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
    _controller.releaseAllControllers();
  }

  @override
  void didPopNext() {
    if (widget.selectedIndex.value == 0) {
      _controller.playVideo(_controller.currentIndex.value);
    }
  }

  void _onPageChanged(int page) {
    // Preload for the new neighbor is scheduled (debounced) inside playVideo —
    // never triggered eagerly here, so a fast multi-page fling doesn't spin up
    // and immediately cancel a controller for every index it passes through.
    _controller.playVideo(page, deferPreload: true);
    HapticFeedback.selectionClick();
    unawaited(_maybeLoadMorePages(page));
  }

  void _onFeedScroll(ScrollNotification notification) {
    if (!_pageController.hasClients) return;

    // Intentionally no ScrollUpdateNotification handling here — warming up a
    // video based on mid-drag position starts real network/decoder work that
    // usually gets cancelled a moment later once the drag settles elsewhere.
    if (notification is ScrollStartNotification && notification.depth == 0) {
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

    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 65 + bottomInset,
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        if (_controller.isCommentsOpen) return;
        _horizontalDragDistance = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        if (_controller.isCommentsOpen) return;
        _horizontalDragDistance += details.primaryDelta ?? 0.0;
      },
      onHorizontalDragCancel: () {
        _horizontalDragDistance = 0.0;
      },
      onHorizontalDragEnd: (details) {
        if (_controller.isCommentsOpen) return;
        final velocity = details.primaryVelocity ?? 0.0;
        const minDistance = 50.0;
        const minVelocity = 250.0;

        // Swipe right (left to right) -> Subscribed
        if (velocity > minVelocity || _horizontalDragDistance > minDistance) {
          if (selectedContentTab != 'Subscribed') {
            HapticFeedback.lightImpact();
            _onTabChanged('Subscribed');
          }
        }
        // Swipe left (right to left) -> For You
        else if (velocity < -minVelocity ||
            _horizontalDragDistance < -minDistance) {
          if (selectedContentTab != 'For You') {
            HapticFeedback.lightImpact();
            _onTabChanged('For You');
          }
        }
        _horizontalDragDistance = 0.0;
      },
      child: Stack(
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
                        !_controller.isCommentsOpen &&
                        notification.depth == 0 &&
                        _controller.currentIndex.value == 0,
                    onRefresh: _refreshFeed,
                    color: Colors.white,
                    backgroundColor: Colors.grey[800],
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _controller.isCommentsOpenNotifier,
                      builder: (context, isCommentsOpen, _) {
                        return PageView.builder(
                          key: ValueKey(_controller.currentFeed),
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          allowImplicitScrolling: true,
                          onPageChanged: _onPageChanged,
                          itemCount: _controller.mediaUrls.length,
                          physics: isCommentsOpen
                              ? const NeverScrollableScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(
                                  parent: PageScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                ),
                          itemBuilder: (context, index) {
                            final post = _controller.posts[index];
                            final url = _controller.mediaUrls[index].trim();
                            return FeedItemWidget(
                              key: ValueKey(
                                post.id.isNotEmpty
                                    ? 'feed_${post.id}'
                                    : 'feed_$url',
                              ),
                              index: index,
                              controller: _controller,
                              selectedTab: selectedContentTab,
                              onTabChanged: _onTabChanged,
                              onOwnProfileTap: () => widget.onTabChanged(4),
                            );
                          },
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
      ),
    );
  }
}

class PlayPauseAnimationOverlay extends StatefulWidget {
  final bool isPlaying;

  const PlayPauseAnimationOverlay({super.key, required this.isPlaying});

  @override
  State<PlayPauseAnimationOverlay> createState() =>
      _PlayPauseAnimationOverlayState();
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
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 0.9), weight: 30),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.9,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
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
                    widget.isPlaying
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
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

class FeedItemWidget extends ConsumerStatefulWidget {
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
  ConsumerState<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _HeartTapInfo {
  final int id;
  final Offset position;
  _HeartTapInfo({required this.id, required this.position});
}

class _FeedItemWidgetState extends ConsumerState<FeedItemWidget>
    with SingleTickerProviderStateMixin {
  bool _isPausedByUser = false;
  bool _overlayIsPlayingIcon = false;
  int _overlayTriggerCounter = 0;
  final List<_HeartTapInfo> _activeHearts = [];
  Offset? _lastDoubleTapPosition;
  int _heartCounter = 0;

  late final AnimationController _commentAnimationController;
  late final Animation<double> _commentCurvedAnimation;
  bool _isCommentsOpen = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _commentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _commentCurvedAnimation = CurvedAnimation(
      parent: _commentAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _commentAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.controller.isCommentsOpen = false;
        if (mounted) {
          setState(() {
            _isCommentsOpen = false;
          });
        }
      } else if (status == AnimationStatus.forward) {
        widget.controller.isCommentsOpen = true;
      }
    });
  }

  @override
  void dispose() {
    _commentAnimationController.dispose();
    super.dispose();
  }

  void _openComments() {
    setState(() {
      _isCommentsOpen = true;
    });
    widget.controller.isCommentsOpen = true;
    _commentAnimationController.forward();
  }

  void _closeComments() {
    FocusScope.of(context).unfocus();
    _commentAnimationController.reverse();
  }

  void _toggleMute() {
    final videoController = widget.controller.controllerForMediaIndex(
      widget.index,
    );
    if (videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      videoController.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _onVideoTap() {
    widget.controller.togglePlayPause();
    final videoController = widget.controller.controllerForMediaIndex(
      widget.index,
    );
    final isPlaying = videoController?.value.isPlaying ?? false;
    setState(() {
      _isPausedByUser = !isPlaying;
      _overlayIsPlayingIcon = isPlaying;
      _overlayTriggerCounter++;
    });
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _lastDoubleTapPosition = details.localPosition;
  }

  void _onDoubleTap(Post post) {
    final likeState = ref.read(postLikeNotifierProvider);
    if (!likeState.isLiked(post)) {
      ref.read(postLikeNotifierProvider.notifier).toggleLike(post);
    } else {
      HapticFeedback.mediumImpact();
    }
    final position = _lastDoubleTapPosition ?? const Offset(200, 350);
    final tapId = ++_heartCounter;
    setState(() {
      _activeHearts.add(_HeartTapInfo(id: tapId, position: position));
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
      builder: (context, _, _) => _buildFeedItem(),
    );
  }

  Widget _buildFeedItem() {
    final url = widget.controller.mediaUrls[widget.index].trim();
    final post = widget.controller.posts[widget.index];
    final effectiveVideo = post.isVideo || Post.mediaUrlLooksLikeVideo(url);
    final isValidNetworkUrl = _isNetworkMediaUrl(url);
    final videoController = widget.controller.controllerForMediaIndex(
      widget.index,
    );

    return RepaintBoundary(
      child: PopScope(
        canPop: !_isCommentsOpen && _commentAnimationController.value == 0.0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop &&
              (_isCommentsOpen || _commentAnimationController.value > 0.0)) {
            _closeComments();
          }
        },
        child: AnimatedBuilder(
          animation: _commentCurvedAnimation,
          builder: (context, _) {
            final t = _commentCurvedAnimation.value;
            final isAnimatingOrOpen = t > 0.0 || _isCommentsOpen;
            final screenSize = MediaQuery.sizeOf(context);
            final topPadding = MediaQuery.paddingOf(context).top;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final keyboardProgress = (keyboardInset / 280.0).clamp(0.0, 1.0);

            // Target top video card layout in comments mode (9:16 portrait aspect ratio matching screenshot)
            // When keyboard opens, dynamically compact the video card height so comments remain completely visible and scrollable
            final normalTargetHeight = screenSize.height * 0.38;
            final keyboardTargetHeight = (screenSize.height * 0.16).clamp(
              100.0,
              130.0,
            );
            final targetHeight = lerpDouble(
              normalTargetHeight,
              keyboardTargetHeight,
              keyboardProgress,
            )!;

            final normalTargetTop = topPadding + 6.0;
            final keyboardTargetTop = topPadding + 2.0;
            final targetTop = lerpDouble(
              normalTargetTop,
              keyboardTargetTop,
              keyboardProgress,
            )!;

            final targetWidth = targetHeight * (9.0 / 16.0);
            final targetHoriz = ((screenSize.width - targetWidth) / 2).clamp(
              0.0,
              screenSize.width / 2,
            );
            final targetRadius = lerpDouble(26.0, 18.0, keyboardProgress)!;

            final currentTop = lerpDouble(0.0, targetTop, t)!;
            final currentHoriz = lerpDouble(0.0, targetHoriz, t)!;
            final currentHeight = lerpDouble(
              screenSize.height,
              targetHeight,
              t,
            )!;
            final currentRadius = lerpDouble(0.0, targetRadius, t)!;

            return Stack(
              children: [
                // Solid black background behind entire feed item
                Positioned.fill(child: Container(color: Colors.black)),

                // Video Container that smoothly morphs size, position, and corner radius
                Positioned(
                  top: currentTop,
                  left: currentHoriz,
                  right: currentHoriz,
                  height: currentHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(currentRadius),
                    child: Stack(
                      children: [
                        // Media content
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: effectiveVideo ? _onVideoTap : null,
                            onDoubleTapDown: isAnimatingOrOpen
                                ? null
                                : _onDoubleTapDown,
                            onDoubleTap: isAnimatingOrOpen
                                ? null
                                : () => _onDoubleTap(post),
                            child: Container(
                              color: Colors.black,
                              child: FeedMediaContent(
                                index: widget.index,
                                controller: widget.controller,
                                url: url,
                                posterUrl: post.feedPosterUrl,
                                isVideo: effectiveVideo,
                                isValidNetworkUrl: isValidNetworkUrl,
                                postId: post.id,
                                authorUserId: post.userId,
                              ),
                            ),
                          ),
                        ),

                        // Normal Overlays (User info + action buttons)
                        if (t < 0.99)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: isAnimatingOrOpen,
                              child: Opacity(
                                opacity: (1.0 - (t * 1.5)).clamp(0.0, 1.0),
                                child: ValueListenableBuilder<int>(
                                  valueListenable:
                                      widget.controller.currentIndex,
                                  builder: (context, currentIdx, overlayStack) {
                                    return Offstage(
                                      offstage: currentIdx != widget.index,
                                      child: overlayStack,
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      OptimizedVideoOverlay(
                                        selectedTab: widget.selectedTab,
                                        onTabChanged: widget.onTabChanged,
                                        controller: widget.controller,
                                        onOwnProfileTap: widget.onOwnProfileTap,
                                        currentIndex: widget.index,
                                        onComment: _openComments,
                                      ),
                                      if (effectiveVideo &&
                                          _overlayTriggerCounter > 0)
                                        PlayPauseAnimationOverlay(
                                          key: ValueKey(_overlayTriggerCounter),
                                          isPlaying: _overlayIsPlayingIcon,
                                        ),
                                      ..._activeHearts.map((heart) {
                                        return DoubleTapHeartOverlay(
                                          key: ValueKey('heart_${heart.id}'),
                                          position: heart.position,
                                          onAnimationComplete: () {
                                            if (mounted) {
                                              setState(() {
                                                _activeHearts.removeWhere(
                                                  (h) => h.id == heart.id,
                                                );
                                              });
                                            }
                                          },
                                        );
                                      }),
                                      if (_isPausedByUser &&
                                          effectiveVideo &&
                                          videoController != null)
                                        ValueListenableBuilder<
                                          VideoPlayerValue
                                        >(
                                          valueListenable: videoController,
                                          builder: (context, value, child) {
                                            if (!value.isInitialized ||
                                                value.isPlaying) {
                                              return const SizedBox.shrink();
                                            }
                                            return IgnorePointer(
                                              child: Center(
                                                child: Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
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
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Volume / Mute indicator button in bottom right of scaled video
                        if (isAnimatingOrOpen && t > 0.3 && effectiveVideo)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Opacity(
                              opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
                              child: GestureDetector(
                                onTap: _toggleMute,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Top backdrop click-outside area to close comment sheet
                if (isAnimatingOrOpen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: currentTop + currentHeight + 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _closeComments,
                      child: const SizedBox.expand(),
                    ),
                  ),

                // Comment Sheet sliding in from bottom up to docked position
                if (isAnimatingOrOpen)
                  Positioned(
                    top: currentTop + currentHeight + 8,
                    left: 0,
                    right: 0,
                    bottom: keyboardInset,
                    child: RepaintBoundary(
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          (1.0 - t) * (screenSize.height * 0.65),
                        ),
                        child: GestureDetector(
                          onVerticalDragUpdate: (details) {
                            if (details.primaryDelta! > 0) {
                              _commentAnimationController.value -=
                                  details.primaryDelta! /
                                  (screenSize.height * 0.65);
                            }
                          },
                          onVerticalDragEnd: (details) {
                            if (_commentAnimationController.value < 0.75 ||
                                (details.primaryVelocity ?? 0) > 300) {
                              _closeComments();
                            } else {
                              _commentAnimationController.forward();
                            }
                          },
                          child: CommentSheet(
                            key: ValueKey('comment_sheet_${post.id}'),
                            postId: post.id,
                            isEmbedded: true,
                            onClose: _closeComments,
                            onCommentAdded: () {
                              if (mounted) {
                                setState(() {
                                  post.commentsCount++;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
        errorWidget: (context, url, error) =>
            const ColoredBox(color: Colors.black),
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
    final ready =
        controller != null &&
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
  final String postId;
  final String authorUserId;

  const FeedMediaContent({
    super.key,
    required this.index,
    required this.controller,
    required this.url,
    this.posterUrl = '',
    required this.isVideo,
    required this.isValidNetworkUrl,
    this.postId = '',
    this.authorUserId = '',
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
      postId: postId,
      authorUserId: authorUserId,
    );
  }

  Widget _buildImage(BuildContext context) {
    if (!isValidNetworkUrl) {
      AppLogger.d('❌ image filtered/skipped — bad network URL url=$url');
      return _brokenMediaIcon();
    }

    return PostViewTracker(
      postId: postId,
      authorUserId: authorUserId,
      child: FeedPosterImage(url: url),
    );
  }
}

/// Fires the post-view API once a post crosses 50% visibility in the
/// viewport — no dwell delay. Skips posts already recorded this session
/// and posts authored by the logged-in user.
class PostViewTracker extends ConsumerWidget {
  final String postId;
  final String authorUserId;
  final Widget child;

  const PostViewTracker({
    super.key,
    required this.postId,
    required this.authorUserId,
    required this.child,
  });

  void _onVisibilityChanged(WidgetRef ref, VisibilityInfo info) {
    if (info.visibleFraction < 0.5) return;
    if (postId.isEmpty) return;
    if (ref.read(postViewNotifierProvider.notifier).isViewed(postId)) return;

    final myUserId = ProfileIdentityService.instance.cachedLoggedInUserId;
    if (myUserId != null &&
        authorUserId.isNotEmpty &&
        myUserId == authorUserId) {
      return;
    }

    ref.read(postViewNotifierProvider.notifier).recordView(postId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (postId.isEmpty) return child;

    return VisibilityDetector(
      key: ValueKey('post-view-$postId'),
      onVisibilityChanged: (info) => _onVisibilityChanged(ref, info),
      child: child,
    );
  }
}

/// Keeps a stable [VideoPlayer] instance so the texture is not torn down
/// every time a neighboring slot finishes loading.
class FeedVideoPlayer extends ConsumerStatefulWidget {
  final int index;
  final VideoFeedController controller;
  final String url;
  final String posterUrl;
  final String postId;
  final String authorUserId;

  const FeedVideoPlayer({
    super.key,
    required this.index,
    required this.controller,
    required this.url,
    this.posterUrl = '',
    this.postId = '',
    this.authorUserId = '',
  });

  @override
  ConsumerState<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends ConsumerState<FeedVideoPlayer> {
  VideoPlayerController? _boundController;
  bool _initialized = false;

  /// Sticky — once the first frame is shown, never fall back to shimmer on
  /// transient buffering or decoder surface recovery (Exynos freeAllBuffers).
  bool _hasEverRenderedFrame = false;
  bool _showPlaybackBufferSpinner = false;
  Timer? _bufferingShowTimer;

  /// True once this item is known to be off-screen with a controller already
  /// bound (i.e. it was preloaded). Only that case needs the defensive
  /// texture-recovery rebuild in [_onCurrentIndexChanged] — a controller that
  /// attaches while already current triggers its own rebuild via
  /// [_syncController], so a second blanket rebuild right after would be
  /// redundant.
  bool _needsCurrentIndexRebuildKick = false;

  /// Last state [_syncController] observed, so it can skip rebuilding when
  /// nothing relevant to this item actually changed on a global
  /// [VideoFeedController.videoControllersRevision] tick caused by some other
  /// slot in the feed.
  bool _lastObservedFailed = false;
  bool _lastObservedInitializing = false;

  static const Duration _bufferingSpinnerShowDelay = Duration(
    milliseconds: 400,
  );

  /// Fires the view API once this post has played continuously for this
  /// long. Restarts from zero on pause/leaving current — an approximation
  /// of "3 seconds of playback", not accumulated watch time.
  static const Duration _viewThreshold = Duration(seconds: 3);
  Timer? _viewTimer;

  bool get _isCurrentItem =>
      widget.controller.currentIndex.value == widget.index;

  bool _hasVisibleFrame(VideoPlayerValue value) {
    return value.isInitialized && value.size.width > 0 && value.size.height > 0;
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

    final awaitingFirstFrame = !value.isInitialized || !_hasEverRenderedFrame;
    if (awaitingFirstFrame) {
      _cancelBufferingShowTimer();
      if (_showPlaybackBufferSpinner) {
        setState(() => _showPlaybackBufferSpinner = false);
      }
      return;
    }

    if (value.isBuffering) {
      if (_showPlaybackBufferSpinner ||
          (_bufferingShowTimer?.isActive ?? false)) {
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

  void _cancelViewTimer() {
    _viewTimer?.cancel();
    _viewTimer = null;
  }

  void _syncViewTracking(VideoPlayerValue value) {
    if (widget.postId.isEmpty) return;

    if (!_isCurrentItem || !value.isInitialized || !value.isPlaying) {
      _cancelViewTimer();
      return;
    }

    if (_viewTimer != null) return;
    if (ref.read(postViewNotifierProvider.notifier).isViewed(widget.postId)) {
      return;
    }

    final myUserId = ProfileIdentityService.instance.cachedLoggedInUserId;
    if (myUserId != null &&
        widget.authorUserId.isNotEmpty &&
        myUserId == widget.authorUserId) {
      return;
    }

    _viewTimer = Timer(_viewThreshold, () {
      _viewTimer = null;
      if (!mounted) return;
      ref.read(postViewNotifierProvider.notifier).recordView(widget.postId);
    });
  }

  @override
  void initState() {
    super.initState();
    _needsCurrentIndexRebuildKick = !_isCurrentItem;
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
    _cancelViewTimer();
    _detachController();
    super.dispose();
  }

  void _onCurrentIndexChanged() {
    if (widget.controller.currentIndex.value != widget.index) {
      // Leaving current — arm the recovery kick so the next arrival (even a
      // revisit of an already-cached slot) still gets it, matching the prior
      // unconditional behavior for every real "become current" transition.
      _needsCurrentIndexRebuildKick = true;
      _cancelBufferingShowTimer();
      _cancelViewTimer();
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
    _syncViewTracking(ctrl.value);

    // Recover from a stale black texture after swiping onto a preloaded slot.
    // Only needed when the controller was already sitting there from an
    // earlier preload — a controller that attached in this same cycle while
    // already current already triggers its own rebuild via _syncController,
    // so a second blanket setState here would just be a redundant rebuild.
    if (_needsCurrentIndexRebuildKick) {
      _needsCurrentIndexRebuildKick = false;
      if (mounted) setState(() {});
    }
  }

  void _detachController() {
    _cancelBufferingShowTimer();
    _cancelViewTimer();
    _showPlaybackBufferSpinner = false;
    _boundController?.removeListener(_onControllerUpdate);
    _boundController = null;
    _initialized = false;
    _hasEverRenderedFrame = false;
    // Force the next _syncController() call to re-evaluate from scratch
    // (relevant when widget.index itself changes, e.g. didUpdateWidget).
    _lastObservedFailed = false;
    _lastObservedInitializing = false;
  }

  // Single gate for everything `videoControllersRevision` can affect for this
  // item (controller identity, load-failure, initializing flag). Listening to
  // this per-widget instance means a controller change for a DIFFERENT index
  // only costs a few cheap lookups here — no setState, no rebuild — instead of
  // the unconditional rebuild every alive FeedVideoPlayer used to take on
  // every tick of the shared, feed-wide revision counter.
  void _syncController() {
    final failed = widget.controller.hasVideoLoadFailed(widget.index);
    final initializing = widget.controller.isVideoInitializing(widget.index);
    final next = failed
        ? null
        : widget.controller.controllerForMediaIndex(widget.index);

    final relevantStateChanged =
        failed != _lastObservedFailed ||
        initializing != _lastObservedInitializing ||
        !identical(next, _boundController);

    _lastObservedFailed = failed;
    _lastObservedInitializing = initializing;

    if (!relevantStateChanged) return;

    if (failed) {
      if (_boundController != null) _detachController();
      setState(() {});
      return;
    }

    _boundController?.removeListener(_onControllerUpdate);
    _boundController = next;
    _initialized = next?.value.isInitialized ?? false;
    if (next != null && _hasVisibleFrame(next.value)) {
      _hasEverRenderedFrame = true;
    }
    _boundController?.addListener(_onControllerUpdate);
    if (next != null) {
      _syncPlaybackBufferSpinner(next.value);
      _syncViewTracking(next.value);
    } else {
      _cancelViewTimer();
    }
    setState(() {});
  }

  void _onControllerUpdate() {
    final ctrl = _boundController;
    if (ctrl == null) return;

    final nowInitialized = ctrl.value.isInitialized;
    final nowHasFrame = _hasVisibleFrame(ctrl.value);
    _syncPlaybackBufferSpinner(ctrl.value);
    _syncViewTracking(ctrl.value);
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
    // No ValueListenableBuilder on the shared, feed-wide videoControllersRevision
    // here — _syncController (wired in initState) already listens to it and
    // calls setState only when this item's own controller/failed/initializing
    // state actually changed, so an unrelated slot's controller update no
    // longer forces this widget to rebuild too.
    return _buildVideoContent(context);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
              child: _buildPoster(context, allowShimmer: _awaitingFirstFrame),
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
