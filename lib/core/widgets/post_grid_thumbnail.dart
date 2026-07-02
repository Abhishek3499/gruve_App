import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:video_player/video_player.dart';

/// Renders an image URL or the first frame of a video URL (profile grid, highlights).
class MediaUrlThumbnail extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? fallback;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const MediaUrlThumbnail({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.fallback,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  static bool isHttpUrl(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Preload thumbnails for smoother profile/highlight/explore grids.
  static Future<void> warmup(String url, {BuildContext? context}) async {
    final mediaUrl = url.trim();
    if (!isHttpUrl(mediaUrl)) return;

    if (Post.mediaUrlLooksLikeVideo(mediaUrl)) {
      await VideoFrameCache.warmup(mediaUrl);
      return;
    }

    try {
      if (context != null && context.mounted) {
        await precacheImage(CachedNetworkImageProvider(mediaUrl), context);
      } else {
        await _precacheImageUrl(mediaUrl);
      }
    } catch (_) {}
  }

  static Future<void> _precacheImageUrl(String url) async {
    final provider = CachedNetworkImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (_, _) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_, _) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    stream.addListener(listener);
    try {
      await completer.future.timeout(const Duration(seconds: 10));
    } catch (_) {
    } finally {
      stream.removeListener(listener);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = url.trim();
    if (mediaUrl.isEmpty || !isHttpUrl(mediaUrl)) {
      return fallback ?? const _ThumbnailFallback();
    }

    if (Post.mediaUrlLooksLikeVideo(mediaUrl)) {
      return _VideoFrameThumbnail(
        videoUrl: mediaUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: placeholder,
        fallback: fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth ?? 300,
      memCacheHeight: memCacheHeight ?? 400,
      maxWidthDiskCache: 600,
      maxHeightDiskCache: 800,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (context, _) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, _, _) => fallback ?? const _ThumbnailFallback(),
    );
  }
}

/// Instagram-style profile grid thumbnail: poster image → video frame → retry.
class PostGridThumbnail extends StatelessWidget {
  final Post post;

  const PostGridThumbnail({super.key, required this.post});

  static Future<void> warmupPost(Post post) async {
    final images = <String>{};
    final videos = <String>{};
    _collectWarmupUrls(post, images, videos);

    await Future.wait([
      if (images.isNotEmpty) _warmupImagesParallel(images.toList()),
      if (videos.isNotEmpty) VideoFrameCache.warmupMany(videos),
    ]);
  }

  static void warmupPosts(Iterable<Post> posts, {int max = 60}) {
    unawaited(warmupPostsAwait(posts, max: max));
  }

  static Future<void> warmupPostsAwait(
    Iterable<Post> posts, {
    int max = 60,
    int concurrency = 12,
  }) async {
    final images = <String>{};
    final videos = <String>{};

    for (final post in posts.take(max)) {
      _collectWarmupUrls(post, images, videos);
    }

    if (images.isEmpty && videos.isEmpty) return;

    await Future.wait([
      if (images.isNotEmpty)
        _warmupImagesParallel(images.toList(), concurrency: concurrency),
      if (videos.isNotEmpty)
        VideoFrameCache.warmupMany(videos, concurrency: concurrency),
    ]);
  }

  static void _collectWarmupUrls(
    Post post,
    Set<String> images,
    Set<String> videos,
  ) {
    final preview = post.gridPreviewUrl.trim();
    if (preview.isNotEmpty &&
        MediaUrlThumbnail.isHttpUrl(preview) &&
        !Post.mediaUrlLooksLikeVideo(preview)) {
      images.add(preview);
    }

    if (!post.isVideo) return;

    final videoUrl = _videoUrlForPost(post);
    if (videoUrl.isNotEmpty) {
      videos.add(videoUrl);
    }
  }

  static String _videoUrlForPost(Post post) {
    final media = post.media.trim();
    if (MediaUrlThumbnail.isHttpUrl(media)) return media;

    final preview = post.gridPreviewUrl.trim();
    if (Post.mediaUrlLooksLikeVideo(preview) &&
        MediaUrlThumbnail.isHttpUrl(preview)) {
      return preview;
    }
    return '';
  }

  static Future<void> _warmupImagesParallel(
    List<String> urls, {
    int concurrency = 12,
  }) async {
    final safeConcurrency = concurrency.clamp(1, 16);
    for (var i = 0; i < urls.length; i += safeConcurrency) {
      final batch = urls.skip(i).take(safeConcurrency);
      await Future.wait(batch.map(MediaUrlThumbnail.warmup));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PostGridThumbnailBody(post: post);
  }
}

class _PostGridThumbnailBody extends StatefulWidget {
  final Post post;

  const _PostGridThumbnailBody({required this.post});

  @override
  State<_PostGridThumbnailBody> createState() => _PostGridThumbnailBodyState();
}

enum _GridThumbSource { image, video, unavailable }

class _PostGridThumbnailBodyState extends State<_PostGridThumbnailBody> {
  late _GridThumbSource _source;

  @override
  void initState() {
    super.initState();
    _source = _initialSource();
  }

  @override
  void didUpdateWidget(covariant _PostGridThumbnailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.gridPreviewUrl != widget.post.gridPreviewUrl ||
        oldWidget.post.media != widget.post.media) {
      _source = _initialSource();
    }
  }

  _GridThumbSource _initialSource() {
    final thumb = widget.post.gridPreviewUrl.trim();
    if (thumb.isNotEmpty &&
        MediaUrlThumbnail.isHttpUrl(thumb) &&
        !Post.mediaUrlLooksLikeVideo(thumb)) {
      return _GridThumbSource.image;
    }
    if (widget.post.isVideo &&
        MediaUrlThumbnail.isHttpUrl(_videoUrlFor(widget.post))) {
      return _GridThumbSource.video;
    }
    return _GridThumbSource.unavailable;
  }

  String _videoUrlFor(Post post) {
    final media = post.media.trim();
    if (MediaUrlThumbnail.isHttpUrl(media)) return media;

    final preview = post.gridPreviewUrl.trim();
    if (Post.mediaUrlLooksLikeVideo(preview) &&
        MediaUrlThumbnail.isHttpUrl(preview)) {
      return preview;
    }
    return '';
  }

  void _fallbackToVideo() {
    if (!mounted) return;
    if (widget.post.isVideo &&
        MediaUrlThumbnail.isHttpUrl(_videoUrlFor(widget.post))) {
      setState(() => _source = _GridThumbSource.video);
    } else {
      setState(() => _source = _GridThumbSource.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    if (_source == _GridThumbSource.image) {
      final imageUrl = post.gridPreviewUrl.trim();
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 280,
        memCacheHeight: 420,
        maxWidthDiskCache: 600,
        maxHeightDiskCache: 800,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (context, _) => _defaultPlaceholder(),
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fallbackToVideo();
          });
          return _defaultPlaceholder();
        },
      );
    }

    final videoUrl = _videoUrlFor(post);
    if (post.isVideo && MediaUrlThumbnail.isHttpUrl(videoUrl)) {
      return _VideoFrameThumbnail(videoUrl: videoUrl);
    }

    return const _ThumbnailFallback();
  }
}

class _VideoFrameThumbnail extends StatefulWidget {
  final String videoUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? fallback;

  const _VideoFrameThumbnail({
    required this.videoUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.fallback,
  });

  @override
  State<_VideoFrameThumbnail> createState() => _VideoFrameThumbnailState();
}

class _VideoFrameThumbnailState extends State<_VideoFrameThumbnail> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _disposed = false;
  int _loadToken = 0;
  int _retryCount = 0;
  late String _boundUrl;

  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _boundUrl = widget.videoUrl.trim();
    final cached = VideoFrameCache.peekReady(_boundUrl);
    if (cached != null) {
      _bindController(cached);
      unawaited(_attachFromCache());
    } else {
      _startLoad();
    }
  }

  void _bindController(VideoPlayerController? controller) {
    _controller?.removeListener(_onControllerUpdate);
    _controller = controller;
    _controller?.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted || _disposed) return;
    setState(() {});
  }

  Future<void> _attachFromCache() async {
    final controller = await VideoFrameCache.acquire(_boundUrl);
    if (!mounted || _disposed) {
      if (controller != null) VideoFrameCache.release(_boundUrl);
      return;
    }
    _bindController(controller);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _VideoFrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl.trim() != widget.videoUrl.trim()) {
      VideoFrameCache.release(_boundUrl);
      _boundUrl = widget.videoUrl.trim();
      _failed = false;
      final cached = VideoFrameCache.peekReady(_boundUrl);
      if (cached != null) {
        _bindController(cached);
        unawaited(_attachFromCache());
      } else {
        _bindController(null);
        _startLoad();
      }
    }
  }

  Future<void> _startLoad() async {
    final token = ++_loadToken;

    final controller = await VideoFrameCache.acquire(_boundUrl);
    if (_disposed || token != _loadToken) {
      if (controller != null) VideoFrameCache.release(_boundUrl);
      return;
    }

    if (controller == null) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final retryDelay = Duration(milliseconds: 200 * _retryCount);
        Future<void>.delayed(retryDelay, () {
          if (_disposed || token != _loadToken || !mounted) return;
          _startLoad();
        });
      } else if (mounted) {
        setState(() => _failed = true);
      }
      return;
    }

    if (!mounted) {
      VideoFrameCache.release(_boundUrl);
      return;
    }

    _bindController(controller);
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _loadToken++;
    _controller?.removeListener(_onControllerUpdate);
    VideoFrameCache.release(_boundUrl);
    _controller = null;
    super.dispose();
  }

  void _retryFromScratch() {
    if (_disposed) return;
    setState(() {
      _failed = false;
      _retryCount = 0;
    });
    _startLoad();
  }

  bool _isFrameReady(VideoPlayerController controller) {
    final size = controller.value.size;
    return controller.value.isInitialized &&
        size.width > 0 &&
        size.height > 0;
  }

  Widget _buildFrame(VideoPlayerController controller) {
    final size = controller.value.size;
    final frame = FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: frame,
      );
    }

    return SizedBox.expand(child: frame);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return GestureDetector(
        onTap: _retryFromScratch,
        child: widget.fallback ?? const _ThumbnailFallback(),
      );
    }

    final controller = _controller;
    final isReady = controller != null && _isFrameReady(controller);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: widget.placeholder ?? _defaultPlaceholder(),
        ),
        if (isReady)
          Positioned.fill(
            child: _buildFrame(controller),
          ),
      ],
    );
  }
}

Widget _defaultPlaceholder() {
  return AppShimmer(
    child: Container(
      color: AppColors.skeletonPlaceholder,
    ),
  );
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        color: AppColors.skeletonPlaceholder,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.white54,
            size: 36,
          ),
        ),
      ),
    );
  }
}
