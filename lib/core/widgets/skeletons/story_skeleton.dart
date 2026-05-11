import 'package:flutter/material.dart';

/// Instagram-style story skeleton loader
class StorySkeleton extends StatelessWidget {
  final bool isHorizontal;

  const StorySkeleton({
    super.key,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _HorizontalStorySkeleton();
    } else {
      return _VerticalStorySkeleton();
    }
  }
}

/// Horizontal story list skeleton (like on profile)
class _HorizontalStorySkeleton extends StatelessWidget {
  const _HorizontalStorySkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => const _StoryCircleSkeleton(),
      ),
    );
  }
}

/// Vertical story skeleton (like in feed)
class _VerticalStorySkeleton extends StatelessWidget {
  const _VerticalStorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Stack(
        children: [
          // Story content skeleton
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
          ),
          // Top bar skeleton
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StoryTopBarSkeleton(),
          ),
          // Bottom bar skeleton
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StoryBottomBarSkeleton(),
          ),
        ],
      ),
    );
  }
}

/// Individual story circle skeleton
class _StoryCircleSkeleton extends StatelessWidget {
  const _StoryCircleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          // Story circle with gradient border
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[700]!,
                  Colors.grey[800]!,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Username skeleton
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Story viewer top bar skeleton
class _StoryTopBarSkeleton extends StatelessWidget {
  const _StoryTopBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Back button skeleton
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // User info skeleton
            Expanded(
              child: Row(
                children: [
                  // Avatar skeleton
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Username skeleton
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // More options skeleton
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Story viewer bottom bar skeleton
class _StoryBottomBarSkeleton extends StatelessWidget {
  const _StoryBottomBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Input field skeleton
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button skeleton
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Story progress bar skeleton
class StoryProgressBarSkeleton extends StatelessWidget {
  const StoryProgressBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: List.generate(
          5,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Story refresh skeleton
class StoryRefreshSkeleton extends StatelessWidget {
  const StoryRefreshSkeleton({super.key});

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
