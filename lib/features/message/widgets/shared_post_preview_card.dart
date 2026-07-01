import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/profile/screens/post_detail/profile_post_detail_screen.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Lightweight in-memory cache so scrolling chat does not refetch posts.
class SharedPostPreviewCache {
  static final Map<String, Post> _posts = {};
  static final Map<String, Future<Post>> _inFlight = {};

  static void set(String postId, Post post) {
    _posts[postId] = post;
  }

  static Future<Post> load(String postId) {
    final cached = _posts[postId];
    if (cached != null && cached.id == postId) {
      return Future.value(cached);
    }
    if (cached != null && cached.id != postId) {
      _posts.remove(postId);
    }

    return _inFlight.putIfAbsent(postId, () async {
      try {
        final post = await PostService().fetchPostById(postId);
        if (post.id == postId) {
          _posts[postId] = post;
        }
        return post;
      } finally {
        _inFlight.remove(postId);
      }
    });
  }

  static void invalidate(String postId) => _posts.remove(postId);
}

/// Instagram-style shared / tagged post preview inside a DM bubble.
class SharedPostPreviewCard extends StatefulWidget {
  final String postId;
  final bool isSent;
  final String? initialPreviewUrl;
  final bool isTaggedPost;
  final Post? preloadedPost;

  const SharedPostPreviewCard({
    super.key,
    required this.postId,
    required this.isSent,
    this.initialPreviewUrl,
    this.isTaggedPost = false,
    this.preloadedPost,
  });

  @override
  State<SharedPostPreviewCard> createState() => _SharedPostPreviewCardState();
}

class _SharedPostPreviewCardState extends State<SharedPostPreviewCard> {
  late Future<Post> _postFuture;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedPost != null && widget.preloadedPost!.username != 'unknown') {
      _postFuture = Future.value(widget.preloadedPost);
      SharedPostPreviewCache.set(widget.postId, widget.preloadedPost!);
    } else {
      _postFuture = SharedPostPreviewCache.load(widget.postId);
    }
  }

  @override
  void didUpdateWidget(covariant SharedPostPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId || oldWidget.preloadedPost != widget.preloadedPost) {
      if (widget.preloadedPost != null && widget.preloadedPost!.username != 'unknown') {
        _postFuture = Future.value(widget.preloadedPost);
        SharedPostPreviewCache.set(widget.postId, widget.preloadedPost!);
      } else {
        _postFuture = SharedPostPreviewCache.load(widget.postId);
      }
    }
  }

  Future<void> _openPost(Post post) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePostDetailScreen(
          post: post,
          allPosts: [post],
          initialIndex: 0,
          isOwnProfile: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.62;

    return FutureBuilder<Post>(
      key: ValueKey('shared_post_future_${widget.postId}'),
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingCard(
            maxWidth: maxWidth,
            previewUrl: widget.initialPreviewUrl,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          AppLogger.d('❌ [SharedPostPreviewCard] FutureBuilder error: ${snapshot.error}, hasData: ${snapshot.hasData}');
          return _ErrorCard(
            maxWidth: maxWidth,
            postId: widget.postId,
            previewUrl: widget.initialPreviewUrl,
            isTaggedPost: widget.isTaggedPost,
            onRetry: () {
              SharedPostPreviewCache.invalidate(widget.postId);
              setState(() {
                _postFuture = PostService().fetchPostById(widget.postId);
              });
            },
          );
        }

        final post = snapshot.data!;
        AppLogger.d('✅ [SharedPostPreviewCard] Loaded post: ${post.id}, media: ${post.media}, isVideo: ${post.isVideo}, gridPreviewUrl: ${post.gridPreviewUrl}');
        return _PostCard(
          post: post,
          maxWidth: maxWidth,
          fallbackPreviewUrl: widget.initialPreviewUrl,
          isTaggedPost: widget.isTaggedPost,
          onTap: () => _openPost(post),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final double maxWidth;
  final VoidCallback onTap;
  final String? fallbackPreviewUrl;
  final bool isTaggedPost;

  const _PostCard({
    required this.post,
    required this.maxWidth,
    required this.onTap,
    this.fallbackPreviewUrl,
    this.isTaggedPost = false,
  });

  @override
  Widget build(BuildContext context) {
    final caption = post.caption.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: maxWidth,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PreviewImage(
                        post: post,
                        fallbackUrl: fallbackPreviewUrl,
                      ),
                      if (post.isVideo)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Avatar(url: post.profilePicture, name: post.username),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentsCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTaggedPost ? 'View tagged post' : 'View post',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
  }
}

class _PreviewImage extends StatelessWidget {
  final Post post;
  final String? fallbackUrl;

  const _PreviewImage({
    required this.post,
    this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.d('🎨 [_PreviewImage] post.id: ${post.id}, isVideo: ${post.isVideo}, media: ${post.media}, gridPreviewUrl: ${post.gridPreviewUrl}, fallbackUrl: $fallbackUrl');
    if (post.gridPreviewUrl.isNotEmpty ||
        (post.isVideo && MediaUrlThumbnail.isHttpUrl(post.media))) {
      return PostGridThumbnail(post: post);
    }

    final url = fallbackUrl?.trim() ?? '';
    if (url.isNotEmpty && MediaUrlThumbnail.isHttpUrl(url)) {
      return MediaUrlThumbnail(url: url);
    }

    return const ColoredBox(
      color: Color(0xFF1A0A22),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;

  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) {
      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      return CircleAvatar(
        radius: 12,
        backgroundColor: const Color(0xFF6A008A),
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.white12,
      backgroundImage: CachedNetworkImageProvider(trimmed),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double maxWidth;
  final String? previewUrl;

  const _LoadingCard({
    required this.maxWidth,
    this.previewUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = previewUrl?.trim() ?? '';
    if (url.isNotEmpty && MediaUrlThumbnail.isHttpUrl(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: maxWidth,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaUrlThumbnail(url: url),
                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: maxWidth,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const AspectRatio(
        aspectRatio: 4 / 5,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final double maxWidth;
  final String postId;
  final String? previewUrl;
  final bool isTaggedPost;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.maxWidth,
    required this.postId,
    this.previewUrl,
    this.isTaggedPost = false,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final url = previewUrl?.trim() ?? '';
    if (url.isNotEmpty && MediaUrlThumbnail.isHttpUrl(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: maxWidth,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaUrlThumbnail(url: url),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isTaggedPost
                                ? 'Tagged post'
                                : 'Shared post',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: maxWidth,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined, color: Colors.white54),
          const SizedBox(height: 8),
          Text(
            'Post unavailable',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
