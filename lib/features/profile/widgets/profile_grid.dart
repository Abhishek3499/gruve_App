import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../../api_calls/profile/controller/profile_controller.dart';
import '../../../features/story_preview/api/create_post_api/model/post_model.dart';
import '../screens/real_draft_screen.dart';

class ProfileGrid extends StatelessWidget {
  final int selectedTab;
  final ProfileController controller;

  const ProfileGrid({
    super.key,
    required this.selectedTab,
    required this.controller,
  });

  List<Post> _postsForTab() {
    final fromApi = controller.getPostsForTab(selectedTab);
    if (selectedTab == 0) {
      return fromApi;
    }
    if (selectedTab == 1) {
      if (fromApi.isNotEmpty) return fromApi;
      final all = controller.getPostsForTab(0);
      final hot = all.where((p) => p.likesCount > 10).toList();
      return hot.isNotEmpty ? hot : all;
    }
    if (fromApi.isNotEmpty) return fromApi;
    return controller.getPostsForTab(0).where((p) => p.isLiked).toList();
  }

  /// Small bottom spinner while the next page loads (non-blocking).
  Widget? _pagingFooter() {
    if (!controller.isLoadingTab(selectedTab)) return null;
    final n = _postsForTab().length;
    if (n == 0) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 4),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  Widget _withPagingFooter(Widget grid) {
    final footer = _pagingFooter();
    if (footer == null) return grid;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [grid, footer],
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _postsForTab();

    if (selectedTab == 2) {
      final likedPosts = posts;
      if (likedPosts.isEmpty) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: Colors.white,
                size: 34,
              ),
              SizedBox(height: 12),
              Text(
                'No liked posts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Posts you like will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return _withPagingFooter(_buildPostsGrid(likedPosts, context));
    }

    final filteredPosts = posts;

    if (selectedTab == 0 && filteredPosts.isNotEmpty) {
      return _withPagingFooter(
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredPosts.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReelsDraftsScreen(),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(AppAssets.frame1, fit: BoxFit.cover),
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: const Text(
                          'Drafts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final post = filteredPosts[index - 1];
            return _buildPostItem(post, context);
          },
        ),
      );
    }

    return _withPagingFooter(_buildPostsGrid(filteredPosts, context));
  }

  Widget _buildPostsGrid(List<Post> posts, BuildContext context) {
    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedTab == 1 ? Icons.trending_up : Icons.video_library_outlined,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              selectedTab == 1 ? 'No trending posts' : 'No posts yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedTab == 1
                  ? 'Trending posts will appear here.'
                  : 'Your posts will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostItem(post, context);
      },
    );
  }

  Widget _buildPostItem(Post post, BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('Tapped on post: ${post.id}');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            post.media.toLowerCase().contains('.mp4')
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  )
                : Image.network(
                    post.media,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 30,
                        ),
                      );
                    },
                  ),
            if (selectedTab == 1 && post.likesCount > 10)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
