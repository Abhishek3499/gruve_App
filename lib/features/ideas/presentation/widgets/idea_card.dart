import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/features/ideas/domain/entities/idea_item.dart';

class IdeaCard extends StatelessWidget {
  final IdeaItem item;

  const IdeaCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AspectRatio(
        aspectRatio: item.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (item.solidColor != null) {
      return Container(
        color: item.solidColor,
      );
    }

    if (item.imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.purple.shade900.withValues(alpha: 0.5),
              highlightColor: Colors.purple.shade700.withValues(alpha: 0.5),
              child: Container(color: Colors.black),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.purple.shade900,
              child: const Icon(Icons.broken_image, color: Colors.white38, size: 24),
            ),
          ),
          if (item.label != null)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.black.withValues(alpha: 0.15),
              child: Text(
                item.label!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Container(color: Colors.grey.shade900);
  }
}
