import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final List<Post> allPosts;
  final int initialIndex;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.allPosts,
    required this.initialIndex,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late Map<int, VideoPlayerController?> _videoControllers;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _videoControllers = {};
    _initializeVideo(_currentIndex);
  }

  void _initializeVideo(int index) {
    if (index >= widget.allPosts.length) return;

    final post = widget.allPosts[index];
    if (post.media.toLowerCase().contains('.mp4') &&
        _videoControllers[index] == null) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(post.media),
      );
      controller
          .initialize()
          .then((_) {
            if (mounted) {
              controller.play();
              setState(() {
                _videoControllers[index] = controller;
              });
            }
          })
          .catchError((e) {
            debugPrint('❌ Video init error: $e');
          });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Pause previous video
    if (_videoControllers[index - 1] != null) {
      _videoControllers[index - 1]?.pause();
    }

    // Initialize next video
    _initializeVideo(index);

    // Preload next video
    if (index + 1 < widget.allPosts.length) {
      _initializeVideo(index + 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for smooth swiping
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.allPosts.length,
            itemBuilder: (context, index) {
              final post = widget.allPosts[index];
              return _buildPostItem(post, index);
            },
          ),

          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    AppAssets.back,
                    color: Colors.white,
                    width: 20,
                    height: 20,
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
    final isVideo = post.media.toLowerCase().contains('.mp4');
    final videoController = _videoControllers[index];

    return Stack(
      children: [
        // Media
        GestureDetector(
          onTap: () {
            if (isVideo && videoController != null) {
              setState(() {
                if (videoController.value.isPlaying) {
                  videoController.pause();
                } else {
                  videoController.play();
                }
              });
            }
          },
          child: Container(
            color: Colors.black,
            child: isVideo
                ? _buildVideoPlayer(videoController)
                : _buildImagePlayer(post.media),
          ),
        ),

        // Bottom gradient + info
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
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: post.profilePicture.isNotEmpty
                          ? CachedNetworkImageProvider(post.profilePicture)
                          : null,
                      child: post.profilePicture.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (post.caption.isNotEmpty)
                            Text(
                              post.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Likes + Comments
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.favorite,
                          count: post.likesCount,
                          onTap: () {
                            // TODO: Like functionality
                          },
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.comment,
                          count: post.commentsCount,
                          onTap: () {
                            // TODO: Comments functionality
                          },
                        ),
                      ],
                    ),

                    // Save button
                    Consumer<SavePostProvider>(
                      builder: (context, provider, _) {
                        final isSaved = provider.isSaved(post.id);
                        final isLoading = provider.isLoading(post.id);

                        return GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  provider.toggleSavePost(post.id);
                                },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.white,
                              size: 24,
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

        // Play button overlay for video
        if (isVideo && videoController != null)
          Center(
            child: AnimatedOpacity(
              opacity: videoController.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildImagePlayer(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
