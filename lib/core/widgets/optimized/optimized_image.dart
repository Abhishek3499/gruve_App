import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized network image with caching and performance features
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
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

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: useMemCache ? width?.toInt() : null,
      memCacheHeight: useMemCache ? height?.toInt() : null,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultError(),
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.medium, // Balance between quality and performance
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width ?? height ?? 48) * 0.3,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width ?? height ?? 48) * 0.3,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: (width ?? height ?? 48) * 0.3,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

/// Optimized avatar component
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
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[800],
        backgroundImage: CachedNetworkImageProvider(
          imageUrl!,
          cacheKey: 'avatar_$imageUrl',
        ),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('❌ [OptimizedAvatar] Failed to load avatar: $imageUrl');
        },
        child: null,
      );
    }

    // Fallback to initials or custom widget
    if (fallback != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[800],
        child: fallback!,
      );
    }

    // Generate initials from name
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Text(
        _getInitials(name ?? 'User'),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0].substring(0, 1).toUpperCase();
    }
  }
}

/// Optimized profile header image
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
          // Main image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.1),
              child: OptimizedImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                useMemCache: true,
              ),
            ),
          ),
          // Optional overlay (like edit button)
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

/// Optimized story image with aspect ratio
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
            useMemCache: true,
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

/// Optimized grid image with loading states
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          child: OptimizedImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            useMemCache: true,
          ),
        ),
      ),
    );
  }
}
