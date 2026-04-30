import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'widgets/post_action_sheet.dart';

class ProfilePostDetailScreen extends StatefulWidget {
  final Post post;
  final List<Post> allPosts;
  final int initialIndex;
  final bool isOwnProfile;

  const ProfilePostDetailScreen({
    super.key,
    required this.post,
    required this.allPosts,
    required this.initialIndex,
    this.isOwnProfile = false,
  });

  @override
  State<ProfilePostDetailScreen> createState() =>
      _ProfilePostDetailScreenState();
}

class _ProfilePostDetailScreenState extends State<ProfilePostDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late Map<int, VideoPlayerController?> _videoControllers;
  late Map<String, bool> _isLiked;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _videoControllers = {};
    _isLiked = {};
    _initializeVideo(_currentIndex);
  }

  void _initializeVideo(int index) {
    if (index >= widget.allPosts.length) return;

    final post = widget.allPosts[index];
    if (post.media.toLowerCase().contains('.mp4') &&
        _videoControllers[index] == null) {
      final controller = VideoPlayerController.network(post.media);
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

    if (_videoControllers[index - 1] != null) {
      _videoControllers[index - 1]?.pause();
    }

    _initializeVideo(index);

    if (index + 1 < widget.allPosts.length) {
      _initializeVideo(index + 1);
    }
  }

  void _toggleLike(String postId) {
    setState(() {
      _isLiked[postId] = !(_isLiked[postId] ?? false);
    });
    debugPrint('❤️ Toggled like for post: $postId');
  }

  void _showActionSheet(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PostActionSheet(post: post, isOwnProfile: widget.isOwnProfile),
    );
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

          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
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

          // Positioned(
          //   top: 16,
          //   right: 16,
          //   child: SafeArea(
          //     child: GestureDetector(
          //       onTap: () => _showActionSheet(widget.allPosts[_currentIndex]),
          //       child: Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //           color: Colors.black.withOpacity(0.5),
          //           shape: BoxShape.circle,
          //         ),
          //         child: const Icon(
          //           Icons.more_vert,
          //           color: Colors.white,
          //           size: 24,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post, int index) {
    final isVideo = post.media.toLowerCase().contains('.mp4');
    final videoController = _videoControllers[index];
    final liked = _isLiked[post.id] ?? post.isLiked;

    return Stack(
      children: [
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
                  Colors.black.withOpacity(0.95),
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          icon: liked ? Icons.favorite : Icons.favorite_border,
                          count: post.likesCount,
                          color: liked ? Colors.red : Colors.white,
                          onTap: () => _toggleLike(post.id),
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.comment_outlined,
                          count: post.commentsCount,
                          onTap: () {
                            debugPrint('💬 Comments tapped');
                          },
                        ),
                        const SizedBox(width: 24),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          count: 0,
                          onTap: () {
                            debugPrint('📤 Share tapped');
                          },
                        ),
                      ],
                    ),

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

        if (isVideo && videoController != null)
          Center(
            child: AnimatedOpacity(
              opacity: videoController.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
