import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// 🚀 Reusable AppCachedImage Widget
/// Leverages CachedNetworkImage with a custom Shimmer loading state and a fallback error widget.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final BoxShape shape;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0.0,
    this.shape = BoxShape.rectangle,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null' || !cleanUrl.startsWith('http')) {
      return _buildErrorWidget();
    }

    final cachedImage = CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholderWidget(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );

    if (shape == BoxShape.circle) {
      return ClipOval(child: cachedImage);
    } else if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: cachedImage,
      );
    }

    return cachedImage;
  }

  Widget _buildPlaceholderWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: Colors.white24,
        size: 24,
      ),
    );
  }
}

/// 🚀 Cached Network Image Provider
/// Use as a direct replacement for NetworkImage() inside BoxDecorations/CircleAvatars.
class AppCachedImageProvider extends CachedNetworkImageProvider {
  const AppCachedImageProvider(super.url);
}
