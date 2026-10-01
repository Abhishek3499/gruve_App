import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/media/video_playback_guard.dart';
import 'package:gruve_app/shared/widgets/shimmer/app_shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/save_post_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/post_like_notifier.dart';
import 'package:gruve_app/features/comments/presentation/widgets/comment_sheet.dart';
import 'package:gruve_app/features/share/presentation/screens/share_bottom_sheet.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/profile/presentation/screens/post_detail/widgets/post_action_sheet.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class ProfilePostDetailScreen extends StatefulWidget {
  final Post post;
  final List<Post> allPosts;
  final int initialIndex;
  final bool isOwnProfile;
  final ProfileController? profileController;
  final String? fallbackDisplayName;
  final String? fallbackMediaUrl;
  final String? fallbackProfilePicture;
  final Future<Post?> Function()? onResolveMedia;

  const ProfilePostDetailScreen({
    super.key,
    required this.post,
    required this.allPosts,
    required this.initialIndex,
    this.isOwnProfile = false,
    this.profileController,
    this.fallbackDisplayName,
    this.fallbackMediaUrl,
    this.fallbackProfilePicture,
    this.onResolveMedia,
  });

  @override
  State<ProfilePostDetailScreen> createState() =>
      _ProfilePostDetailScreenState();
}

class _ProfilePostDetailScreenState extends State<ProfilePostDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<Post> _posts;
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Set<String> _acquiredUrls = <String>{};
  bool _isResolvingMedia = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _posts = List<Post>.from(widget.allPosts);
    _pageController = PageController(initialPage: _currentIndex);
    unawaited(VideoPlaybackGuard.stopAll());
    _bootstrapPlayback();
  }

  Future<void> _bootstrapPlayback() async {
    await _ensureMediaResolved(_currentIndex);
    if (!mounted) return;

    await _initializeVideo(_currentIndex);
    if (!mounted) return;
    await _activateVideoAt(_currentIndex);

    // Preload the next video silently.
    if (_currentIndex + 1 < _posts.length) {
      unawaited(_ensureMediaResolved(_currentIndex + 1));
      unawaited(_preloadVideo(_currentIndex + 1));
    }
  }

  Future<void> _ensureMediaResolved(int index) async {
    if (index < 0 || index >= _posts.length) return;

    final post = _posts[index];
    if (!_needsMediaResolve(post)) return;

    final showLoader = index == _currentIndex;
    if (showLoader && mounted) setState(() => _isResolvingMedia = true);

    try {
      Post? resolved;
      if (widget.onResolveMedia != null && index == widget.initialIndex) {
        resolved = await widget.onResolveMedia!();
      } else {
        resolved = await _fetchPostById(post);
      }

      if (!mounted || resolved == null) return;

      final merged = post.mergedWith(other: resolved);
      if (_needsMediaResolve(merged) && !_hasPlayableVideo(merged)) return;

      _posts[index] = merged;
    } catch (e) {
      AppLogger.d('Media resolve error: $e');
    } finally {
      if (mounted && showLoader) setState(() => _isResolvingMedia = false);
    }
  }

  void _openProfile(Post post) {
    if (post.userId.isEmpty) return;

    final loggedInUserId = AuthStateManager().currentUserId;
    final isOwnProfile =
        widget.isOwnProfile ||
        (loggedInUserId != null &&
            loggedInUserId.isNotEmpty &&
            loggedInUserId.trim() == post.userId.trim());
    if (isOwnProfile) return;

    final displayName = post.resolveUsername(
      fallback: widget.fallbackDisplayName,
    );
    final avatarUrl = post.resolveProfilePicture(
      fallback: widget.fallbackProfilePicture,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          profileUserId: post.userId,
          userName: displayName,
          profileImageUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
        ),
      ),
    );
  }

  Future<Post?> _fetchPostById(Post post) async {
    if (post.id.isEmpty) return null;
    try {
      return await PostService().fetchPostById(
        post.id,
        authorUserId: post.userId,
        allowProfileFallback: true,
      );
    } catch (e) {
      AppLogger.d('fetchPostById error: $e');
      return null;
    }
  }

  bool _needsMediaResolve(Post post) {
    if (post.isVideo) {
      if (!_hasPlayableVideo(post)) return true;
      return post.profilePicture.trim().isEmpty &&
          post.userId.trim().isNotEmpty &&
          post.userId != 'unknown';
    }
    return post.media.trim().isEmpty && post.id.isNotEmpty;
  }

  bool _hasPlayableVideo(Post post) {
    final media = post.media.trim();
    return post.isVideo &&
        media.isNotEmpty &&
        (media.startsWith('http://') || media.startsWith('https://'));
  }

  Future<void> _initializeVideo(int index) async {
    if (index < 0 || index >= _posts.length) return;

    final post = _posts[index];
    final mediaUrl = _mediaUrlFor(post);
    if (!post.isVideo || mediaUrl.isEmpty) return;

    // Controller already exists — nothing to set up.
    if (_videoControllers.containsKey(index)) return;

    final controller = await VideoFrameCache.acquire(mediaUrl);
    if (!mounted) {
      if (controller != null) VideoFrameCache.release(mediaUrl);
      return;
    }
    if (controller == null) {
      // HLS failed/unsupported → drop it for this post and retry with the MP4.
      if (mediaUrl == post.hlsPlaybackUrl && post.media.trim().isNotEmpty) {
        AppLogger.d('HLS failed for ${post.id}, falling back to MP4');
        _posts[index] = post.copyWith(hlsUrl: '');
        unawaited(_initializeVideo(index));
      }
      return;
    }

    _acquiredUrls.add(mediaUrl);
    // Always start silent/paused; caller decides when to activate.
    try {
      if (controller.value.isPlaying) await controller.pause();
      await controller.setVolume(0);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _videoControllers[index] = controller);
  }

  Future<void> _activateVideoAt(int index) async {
    if (index < 0 || index >= _posts.length) return;

    final mediaUrl = _mediaUrlFor(_posts[index]);
    if (mediaUrl.isEmpty) return;

    await VideoPlaybackGuard.activateCacheVideo(mediaUrl);

    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.setLooping(true);
      // Cached players can be parked at the end of a previous playthrough;
      // play() on a finished player is a no-op, so rewind first.
      final value = controller.value;
      final duration = value.duration;
      if (duration > Duration.zero &&
          value.position >= duration - const Duration(milliseconds: 250)) {
        await controller.seekTo(Duration.zero);
      }
      await controller.setVolume(1.0);
      if (!controller.value.isPlaying) {
        await controller.play();
      }
    } catch (e) {
      AppLogger.d('Video play error: $e');
    }

    if (mounted) setState(() {});
  }

  void _onPageChanged(int newIndex) {
    final oldIndex = _currentIndex;
    setState(() => _currentIndex = newIndex);

    // Immediately pause the video that scrolled off.
    final oldController = _videoControllers[oldIndex];
    if (oldController != null) {
      unawaited(() async {
        try {
          if (oldController.value.isPlaying) await oldController.pause();
          await oldController.setVolume(0);
        } catch (_) {}
      }());
    }

    unawaited(() async {
      await _ensureMediaResolved(newIndex);
      if (!mounted || _currentIndex != newIndex) return;

      // Initialize if needed, then always activate — covers both the
      // "first visit" and "returning to a preloaded" controller cases.
      await _initializeVideo(newIndex);
      if (!mounted || _currentIndex != newIndex) return;
      await _activateVideoAt(newIndex);

      // Preload neighbours without activating them.
      if (newIndex + 1 < _posts.length) {
        unawaited(_ensureMediaResolved(newIndex + 1));
        unawaited(_preloadVideo(newIndex + 1));
      }
      if (newIndex - 1 >= 0) unawaited(_preloadVideo(newIndex - 1));
    }());
  }

  /// Initializes a controller for [index] without ever playing it.
  /// Used for neighbour preloading so [_initializeVideo] activation logic
  /// is not accidentally triggered for off-screen indices.
  Future<void> _preloadVideo(int index) async {
    if (index < 0 || index >= _posts.length) return;
    if (_videoControllers.containsKey(index)) return;

    final post = _posts[index];
    final mediaUrl = _mediaUrlFor(post);
    if (!post.isVideo || mediaUrl.isEmpty) return;

    final controller = await VideoFrameCache.acquire(mediaUrl);
    if (!mounted) {
      if (controller != null) VideoFrameCache.release(mediaUrl);
      return;
    }
    if (controller == null) return;

    _acquiredUrls.add(mediaUrl);
    try {
      if (controller.value.isPlaying) await controller.pause();
      await controller.setVolume(0);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _videoControllers[index] = controller);
  }

  void _showCommentSheet(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        postId: post.id,
        onCommentAdded: () {
          if (!mounted) return;
          setState(() => post.commentsCount++);
        },
      ),
    );
  }

  void _showShareSheet(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(postId: post.id),
    );
  }

  void _showOptionsSheet(BuildContext context) async {
    final post = _posts[_currentIndex];
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          PostActionSheet(post: post, isOwnProfile: widget.isOwnProfile),
    );

    if (!mounted) return;

    if (result == 'delete') {
      _confirmAndDeletePost(post);
    }
  }

  void _confirmAndDeletePost(Post post) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: context.rw(28),
            ),
            SizedBox(width: context.rw(10)),
            const Text(
              'Delete Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this post? This action cannot be undone.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: context.rf(14),
            height: 1.4,
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: context.rw(16),
          vertical: context.rh(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: context.rw(16),
                vertical: context.rh(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _deletePost(post);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.loaderDark),
      ),
    );

    final success = await PostService().deletePost(post.id);

    if (!mounted) return;

    Navigator.pop(context);

    if (success) {
      widget.profileController?.removePostLocal(post.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              SizedBox(width: context.rw(10)),
              const Text('Post deleted successfully'),
            ],
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: context.rw(10)),
              const Text('Failed to delete post'),
            ],
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    unawaited(VideoPlaybackGuard.stopAll());
    // Leave shared cached players paused at the first frame, ready for the
    // next viewer (or a thumbnail) instead of parked mid-video / at the end.
    for (final controller in _videoControllers.values) {
      if (controller == null) continue;
      unawaited(() async {
        try {
          await controller.pause();
          await controller.seekTo(Duration.zero);
        } catch (_) {}
      }());
    }
    for (final url in _acquiredUrls) {
      VideoFrameCache.release(url);
    }
    _acquiredUrls.clear();
    _videoControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return _buildPostItem(post, index);
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: BackButton(
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => _showOptionsSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post, int index) {
    final mediaUrl = _mediaUrlFor(post);
    final isVideo = post.isVideo && mediaUrl.isNotEmpty;
    final videoController = _videoControllers[index];
    final displayName = post.resolveUsername(
      fallback: widget.fallbackDisplayName,
    );
    final avatarUrl = post.resolveProfilePicture(
      fallback: widget.fallbackProfilePicture,
    );
    final showResolving = index == _currentIndex && _isResolvingMedia;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (isVideo && videoController != null) {
              if (videoController.value.isPlaying) {
                videoController.pause();
                setState(() {});
              } else {
                unawaited(_activateVideoAt(index));
              }
            }
          },
          child: Container(
            color: Colors.black,
            child: isVideo
                ? _DetailVideoPlayer(
                    controller: showResolving ? null : videoController,
                    posterUrl: post.gridPreviewUrl,
                  )
                : showResolving
                ? const _PostMediaSkeleton()
                : _buildImagePlayer(mediaUrl),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              context.rw(16),
              context.rh(60),
              context.rw(16),
              context.rh(16) + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(post),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF6A008A),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: context.rw(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _openProfile(post),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.rf(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (post.caption.isNotEmpty)
                            Text(
                              post.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: context.rf(12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rh(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final liked = ref.watch(
                              postLikeNotifierProvider.select(
                                (state) => state.isLiked(post),
                              ),
                            );
                            final likesCount = ref.watch(
                              postLikeNotifierProvider.select(
                                (state) => state.likesCount(post),
                              ),
                            );
                            return _buildActionButton(
                              icon: liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              count: likesCount,
                              color: liked ? Colors.red : Colors.white,
                              onTap: () => ref
                                  .read(postLikeNotifierProvider.notifier)
                                  .toggleLike(post),
                            );
                          },
                        ),
                        SizedBox(width: context.rw(24)),
                        _buildActionButton(
                          icon: Icons.comment_outlined,
                          count: post.commentsCount,
                          onTap: () => _showCommentSheet(post),
                        ),
                        SizedBox(width: context.rw(24)),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          count: 0,
                          onTap: () => _showShareSheet(post),
                        ),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isSaved = ref.watch(
                          savePostNotifierProvider.select(
                            (state) => state.isSaved(post.id),
                          ),
                        );
                        return GestureDetector(
                          onTap: () => ref
                              .read(savePostNotifierProvider.notifier)
                              .toggleSavePost(post.id),
                          child: Container(
                            padding: EdgeInsets.all(context.rw(8)),
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.white,
                              size: context.rw(24),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isVideo && videoController != null)
          Center(
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: videoController,
              builder: (context, value, _) => AnimatedOpacity(
                opacity: value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.all(context.rw(16)),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: context.rw(48),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _mediaUrlFor(Post post) {
    if (post.isVideo) {
      final hls = post.hlsPlaybackUrl;
      if (hls.isNotEmpty) return hls;
      final video = post.media.trim();
      if (video.isNotEmpty) return video;
      return widget.fallbackMediaUrl?.trim() ?? '';
    }

    final primary = post.media.trim();
    if (primary.isNotEmpty) return primary;
    final poster = post.gridPreviewUrl.trim();
    if (poster.isNotEmpty) return poster;
    return widget.fallbackMediaUrl?.trim() ?? '';
  }

  Widget _buildImagePlayer(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const _PostMediaSkeleton();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => const _PostMediaSkeleton(),
      errorWidget: (context, url, error) => Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: context.rw(48),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: context.rw(20)),
          SizedBox(width: context.rw(6)),
          Text(
            count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.rf(12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Poster-first video player — reuses grid cache, fades in when first frame renders.
class _DetailVideoPlayer extends StatefulWidget {
  final VideoPlayerController? controller;
  final String posterUrl;

  const _DetailVideoPlayer({required this.controller, required this.posterUrl});

  @override
  State<_DetailVideoPlayer> createState() => _DetailVideoPlayerState();
}

class _DetailVideoPlayerState extends State<_DetailVideoPlayer> {
  bool _hasRenderedFrame = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerUpdate);
    _syncFrameState();
  }

  @override
  void didUpdateWidget(covariant _DetailVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
      _syncFrameState();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    super.dispose();
  }

  bool _computeHasRenderedFrame(VideoPlayerValue value) {
    return value.isInitialized &&
        value.size.width > 0 &&
        value.size.height > 0 &&
        (value.position > Duration.zero || !value.isBuffering);
  }

  void _syncFrameState() {
    final ctrl = widget.controller;
    _hasRenderedFrame = ctrl != null && _computeHasRenderedFrame(ctrl.value);
  }

  void _onControllerUpdate() {
    final ctrl = widget.controller;
    if (ctrl == null) return;
    final nowHasFrame = _computeHasRenderedFrame(ctrl.value);
    if (nowHasFrame != _hasRenderedFrame) {
      setState(() => _hasRenderedFrame = nowHasFrame);
    }
  }

  Widget _buildPoster() {
    final poster = widget.posterUrl.trim();
    if (poster.isEmpty || !poster.startsWith('http')) {
      return const _PostMediaSkeleton();
    }

    final mediaSize = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (mediaSize.width * dpr * 0.8).round().clamp(320, 1080);
    final cacheHeight = (mediaSize.height * dpr * 0.8).round().clamp(640, 1920);

    return CachedNetworkImage(
      imageUrl: poster,
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
      placeholder: (context, url) => const _PostMediaSkeleton(),
      errorWidget: (context, url, error) => const _PostMediaSkeleton(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final showVideo = controller != null && controller.value.isInitialized;
    final hidePoster = showVideo && _hasRenderedFrame;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!hidePoster) _buildPoster(),
        if (showVideo)
          AnimatedOpacity(
            opacity: _hasRenderedFrame ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PostMediaSkeleton extends StatelessWidget {
  const _PostMediaSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.skeletonPlaceholder,
      ),
    );
  }
}
