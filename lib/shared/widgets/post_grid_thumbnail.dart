import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/shared/widgets/shimmer/app_shimmer.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
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
    void addImage(String raw) {
      final value = raw.trim();
      if (value.isNotEmpty &&
          MediaUrlThumbnail.isHttpUrl(value) &&
          !Post.mediaUrlLooksLikeVideo(value)) {
        images.add(value);
      }
    }

    addImage(post.gridPreviewUrl);
    addImage(post.thumbnailUrl);

    if (!post.isVideo) {
      addImage(post.media);
      return;
    }

    final videoUrl = _videoUrlForPost(post);
    if (videoUrl.isNotEmpty) {
      videos.add(videoUrl);
    }
  }

  static String _videoUrlForPost(Post post) {
    return _PostGridThumbnailBodyState.videoUrlFor(post);
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

  static bool isPlayableVideoPost(Post post) {
    if (post.isVideo) return true;
    return Post.mediaUrlLooksLikeVideo(post.media) ||
        Post.mediaUrlLooksLikeVideo(post.gridPreviewUrl);
  }

  static String videoUrlFor(Post post) {
    final media = post.media.trim();
    if (MediaUrlThumbnail.isHttpUrl(media)) return media;

    final preview = post.gridPreviewUrl.trim();
    if (Post.mediaUrlLooksLikeVideo(preview) &&
        MediaUrlThumbnail.isHttpUrl(preview)) {
      return preview;
    }

    final thumb = post.thumbnailUrl.trim();
    if (Post.mediaUrlLooksLikeVideo(thumb) &&
        MediaUrlThumbnail.isHttpUrl(thumb)) {
      return thumb;
    }
    return '';
  }

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
        oldWidget.post.media != widget.post.media ||
        oldWidget.post.thumbnailUrl != widget.post.thumbnailUrl) {
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

    if (!isPlayableVideoPost(widget.post) &&
        MediaUrlThumbnail.isHttpUrl(widget.post.media.trim())) {
      return _GridThumbSource.image;
    }

    if (isPlayableVideoPost(widget.post) &&
        MediaUrlThumbnail.isHttpUrl(videoUrlFor(widget.post))) {
      return _GridThumbSource.video;
    }
    return _GridThumbSource.unavailable;
  }

  String _imageFallbackFor(Post post) {
    for (final candidate in [
      post.thumbnailUrl,
      post.gridPreviewUrl,
      if (!post.isVideo) post.media,
    ]) {
      final value = candidate.trim();
      if (value.isNotEmpty &&
          MediaUrlThumbnail.isHttpUrl(value) &&
          !Post.mediaUrlLooksLikeVideo(value)) {
        return value;
      }
    }
    return '';
  }

  void _fallbackToVideo() {
    if (!mounted) return;
    if (isPlayableVideoPost(widget.post) &&
        MediaUrlThumbnail.isHttpUrl(videoUrlFor(widget.post))) {
      setState(() => _source = _GridThumbSource.video);
    } else {
      setState(() => _source = _GridThumbSource.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    if (_source == _GridThumbSource.image) {
      final imageUrl = post.isVideo
          ? post.gridPreviewUrl.trim()
          : (post.gridPreviewUrl.trim().isNotEmpty
              ? post.gridPreviewUrl.trim()
              : post.media.trim());
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

    final videoUrl = videoUrlFor(post);
    if (isPlayableVideoPost(post) && MediaUrlThumbnail.isHttpUrl(videoUrl)) {
      return _VideoFrameThumbnail(
        videoUrl: videoUrl,
        imageFallbackUrl: _imageFallbackFor(post),
      );
    }

    final imageFallback = _imageFallbackFor(post);
    if (imageFallback.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageFallback,
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
        errorWidget: (context, url, error) => const _ThumbnailFallback(),
      );
    }

    return const _ThumbnailFallback();
  }
}

class _VideoFrameThumbnail extends StatefulWidget {
  final String videoUrl;
  final String imageFallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? fallback;

  const _VideoFrameThumbnail({
    required this.videoUrl,
    this.imageFallbackUrl = '',
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

  static const int _maxRetries = 10;

  @override
  void initState() {
    super.initState();
    _boundUrl = widget.videoUrl.trim();
    _startLoad();
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

  @override
  void didUpdateWidget(covariant _VideoFrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl.trim() != widget.videoUrl.trim()) {
      VideoFrameCache.release(_boundUrl);
      _boundUrl = widget.videoUrl.trim();
      _failed = false;
      _retryCount = 0;
      _bindController(null);
      _startLoad();
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
        final retryDelay = Duration(milliseconds: 350 * _retryCount);
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
    if (!controller.value.isInitialized) return false;
    final size = controller.value.size;
    if (size.width > 0 && size.height > 0) return true;
    return controller.value.aspectRatio > 0;
  }

  Widget _buildFrame(VideoPlayerController controller) {
    final size = controller.value.size;
    final hasSize = size.width > 0 && size.height > 0;
    final aspectRatio = hasSize
        ? size.width / size.height
        : (controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 9 / 16);

    final frame = hasSize
        ? FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          )
        : FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(
              aspectRatio: aspectRatio,
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
      final fallbackImage = widget.imageFallbackUrl.trim();
      if (fallbackImage.isNotEmpty &&
          MediaUrlThumbnail.isHttpUrl(fallbackImage) &&
          !Post.mediaUrlLooksLikeVideo(fallbackImage)) {
        return CachedNetworkImage(
          imageUrl: fallbackImage,
          fit: widget.fit,
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          memCacheWidth: 280,
          memCacheHeight: 420,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, _) =>
              widget.placeholder ?? _defaultPlaceholder(),
          errorWidget: (context, url, error) =>
              widget.fallback ?? const _ThumbnailFallback(),
        );
      }

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
