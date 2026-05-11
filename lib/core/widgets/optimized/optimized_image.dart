import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/debug/debug_logger.dart';
import 'package:shimmer/shimmer.dart';

class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? fadeInDuration;
  final bool useMemCache;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration,
    this.useMemCache = true,
  });

  static String? normalizeImageUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return raw;
    }

    if (raw.startsWith('/')) {
      final base = Uri.tryParse(EnvironmentConfig.baseUrl);
      if (base == null) return null;
      return base.replace(path: raw).toString();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = normalizeImageUrl(imageUrl);
    if (normalizedUrl == null) {
      return errorWidget ?? _buildDefaultError();
    }

    return CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: useMemCache ? _cacheExtent(context, width) : null,
      memCacheHeight: useMemCache ? _cacheExtent(context, height) : null,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 180),
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        debugLog.image(url, operation: 'ERROR', error: error.toString());
        return errorWidget ?? _buildDefaultError();
      },
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }

  int? _cacheExtent(BuildContext context, double? logicalExtent) {
    if (logicalExtent == null || logicalExtent <= 0) return null;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return (logicalExtent * devicePixelRatio).round();
  }

  Widget _buildDefaultPlaceholder() {
    return _ShimmerBox(width: width, height: height);
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: (width ?? height ?? 48) * 0.3,
        color: Colors.grey[600],
      ),
    );
  }
}

class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? name;
  final Widget? fallback;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.name,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final normalizedUrl = OptimizedImage.normalizeImageUrl(imageUrl);

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: normalizedUrl == null
            ? _buildFallback()
            : OptimizedImage(
                imageUrl: normalizedUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: _ShimmerBox(width: size, height: size),
                errorWidget: _buildFallback(),
              ),
      ),
    );
  }

  Widget _buildFallback() {
    if (fallback != null) {
      return ColoredBox(
        color: Colors.grey.shade800,
        child: Center(child: fallback),
      );
    }

    return ColoredBox(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          _getInitials(name ?? 'User'),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.62,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class OptimizedProfileImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Widget? overlay;

  const OptimizedProfileImage({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.1),
              child: OptimizedImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (overlay != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: overlay!,
            ),
        ],
      ),
    );
  }
}

class OptimizedStoryImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double aspectRatio;
  final Widget? overlay;

  const OptimizedStoryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.aspectRatio = 1.0,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final height = width != null ? width! / aspectRatio : null;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OptimizedImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

class OptimizedGridImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const OptimizedGridImage({
    super.key,
    required this.imageUrl,
    this.size = 120,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius = borderRadius ?? BorderRadius.circular(4);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: resolvedBorderRadius,
          child: OptimizedImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;

  const _ShimmerBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade900,
      highlightColor: Colors.grey.shade700,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
