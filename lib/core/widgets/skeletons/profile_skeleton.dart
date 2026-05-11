import 'package:flutter/material.dart';

/// Instagram-style profile skeleton loader
class ProfileSkeleton extends StatelessWidget {
  final bool showGrid;

  const ProfileSkeleton({
    super.key,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Profile header skeleton
          _ProfileHeaderSkeleton(),
          const SizedBox(height: 20),
          // Stats skeleton
          _ProfileStatsSkeleton(),
          const SizedBox(height: 20),
          // Action buttons skeleton
          _ProfileActionsSkeleton(),
          if (showGrid) ...[
            const SizedBox(height: 20),
            // Grid skeleton
            _ProfileGridSkeleton(),
          ],
        ],
      ),
    );
  }
}

/// Profile header with avatar and info skeleton
class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Large avatar skeleton
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 20),
          // Profile info skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username skeleton
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Bio skeleton
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile statistics skeleton
class _ProfileStatsSkeleton extends StatelessWidget {
  const _ProfileStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Posts count skeleton
          _StatSkeleton(label: 'Posts'),
          // Followers count skeleton
          _StatSkeleton(label: 'Followers'),
          // Following count skeleton
          _StatSkeleton(label: 'Following'),
        ],
      ),
    );
  }
}

/// Individual stat skeleton
class _StatSkeleton extends StatelessWidget {
  final String label;

  const _StatSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Number skeleton
        Container(
          width: 40,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        // Label skeleton
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Profile action buttons skeleton
class _ProfileActionsSkeleton extends StatelessWidget {
  const _ProfileActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Follow/Edit button skeleton
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Message button skeleton
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // More options button skeleton
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile grid skeleton
class _ProfileGridSkeleton extends StatelessWidget {
  const _ProfileGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) => Container(
        color: Colors.grey[900],
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 24,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// Compact profile header skeleton (for refresh)
class ProfileRefreshSkeleton extends StatelessWidget {
  const ProfileRefreshSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
