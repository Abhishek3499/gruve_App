import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
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

  /// Preload thumbnails for smoother profile/highlight UI.
  static Future<void> warmup(String url, {BuildContext? context}) async {
    final mediaUrl = url.trim();
    if (!isHttpUrl(mediaUrl)) return;

    if (Post.mediaUrlLooksLikeVideo(mediaUrl)) {
      await VideoFrameCache.warmup(mediaUrl);
      return;
    }

    if (context != null && context.mounted) {
      try {
        await precacheImage(CachedNetworkImageProvider(mediaUrl), context);
      } catch (_) {}
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

/// Instagram-style profile grid thumbnail: API poster first, video frame fallback.
class PostGridThumbnail extends StatelessWidget {
  final Post post;

  const PostGridThumbnail({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.gridPreviewUrl;
    if (imageUrl.isNotEmpty && MediaUrlThumbnail.isHttpUrl(imageUrl)) {
      return MediaUrlThumbnail(
        url: imageUrl,
        memCacheWidth: 300,
        memCacheHeight: 400,
      );
    }

    if (post.isVideo && MediaUrlThumbnail.isHttpUrl(post.media)) {
      return MediaUrlThumbnail(url: post.media.trim());
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
  late String _boundUrl;

  @override
  void initState() {
    super.initState();
    _boundUrl = widget.videoUrl.trim();
    final cached = VideoFrameCache.peekReady(_boundUrl);
    if (cached != null) {
      _controller = cached;
      unawaited(_attachFromCache());
    } else {
      _startLoad();
    }
  }

  Future<void> _attachFromCache() async {
    final controller = await VideoFrameCache.acquire(_boundUrl);
    if (!mounted || _disposed) {
      if (controller != null) VideoFrameCache.release(_boundUrl);
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void didUpdateWidget(covariant _VideoFrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl.trim() != widget.videoUrl.trim()) {
      VideoFrameCache.release(_boundUrl);
      _boundUrl = widget.videoUrl.trim();
      _controller = null;
      _failed = false;
      final cached = VideoFrameCache.peekReady(_boundUrl);
      if (cached != null) {
        _controller = cached;
        unawaited(_attachFromCache());
      } else {
        _startLoad();
      }
    }
  }

  Future<void> _startLoad() async {
    final token = ++_loadToken;

    await _VideoInitLimiter.run(() async {
      if (_disposed || token != _loadToken) return;

      final controller = await VideoFrameCache.acquire(_boundUrl);
      if (_disposed || token != _loadToken) {
        if (controller != null) VideoFrameCache.release(_boundUrl);
        return;
      }

      if (controller == null) {
        if (mounted) setState(() => _failed = true);
        return;
      }

      if (!mounted) {
        VideoFrameCache.release(_boundUrl);
        return;
      }

      setState(() => _controller = controller);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _loadToken++;
    VideoFrameCache.release(_boundUrl);
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.fallback ?? const _ThumbnailFallback();
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return widget.placeholder ?? _defaultPlaceholder();
    }

    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return widget.fallback ?? const _ThumbnailFallback();
    }

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
}

/// Caps concurrent video thumbnail initializations to avoid decoder spikes.
class _VideoInitLimiter {
  static const int _maxConcurrent = 4;
  static int _active = 0;
  static final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  static Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  static Future<void> _acquire() async {
    if (_active < _maxConcurrent) {
      _active++;
      return;
    }

    final waiter = Completer<void>();
    _waitQueue.add(waiter);
    await waiter.future;
    _active++;
  }

  static void _release() {
    _active--;
    if (_waitQueue.isEmpty) return;

    final next = _waitQueue.removeFirst();
    if (!next.isCompleted) {
      next.complete();
    }
  }
}

Widget _defaultPlaceholder() {
  return Container(
    color: Colors.grey.withValues(alpha: 0.2),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: AppColors.loaderDark,
          strokeWidth: 2,
        ),
      ),
    ),
  );
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white54,
          size: 40,
        ),
      ),
    );
  }
}
