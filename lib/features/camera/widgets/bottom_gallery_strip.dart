import 'package:flutter/material.dart';
import '../utils/camera_logger.dart';

/// Dumb UI widget for bottom gallery strip showing recent captures
/// Only handles UI rendering and user interaction callbacks
class BottomGalleryStrip extends StatelessWidget {
  const BottomGalleryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGalleryHeader(),
        const SizedBox(height: 8),
        _buildGalleryStrip(),
      ],
    );
  }

  Widget _buildGalleryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            CameraLogger.logUserAction('View all gallery button pressed');
            _showComingSoon('Gallery');
          },
          child: const Text(
            'View All',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryStrip() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // Mock data - would come from actual gallery
        itemBuilder: (context, index) {
          return _buildGalleryItem(index);
        },
      ),
    );
  }

  Widget _buildGalleryItem(int index) {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Gallery item $index tapped');
        _showComingSoon('Image Preview');
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: _buildItemContent(index),
      ),
    );
  }

  Widget _buildItemContent(int index) {
    // Mock content - would show actual thumbnail
    if (index == 0) {
      // Show placeholder for "no recent photos"
      return const Icon(Icons.image, color: Colors.white54, size: 24);
    } else {
      // Show mock thumbnail
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: LinearGradient(
            colors: [
              Colors.purple.withValues(alpha: 0.3),
              Colors.blue.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 16),
      );
    }
  }

  void _showComingSoon(String feature) {
    // This would show a toast or snackbar
    // For now, just log the action
    CameraLogger.logUserAction('$feature feature requested (coming soon)');
  }
}
