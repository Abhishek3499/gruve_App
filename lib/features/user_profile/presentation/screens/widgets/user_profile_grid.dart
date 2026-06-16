import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/data/controller/user_profile_controller.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/profile/screens/post_detail/profile_post_detail_screen.dart';
import 'package:gruve_app/core/widgets/app_cached_image.dart';

class UserProfileGrid extends StatelessWidget {
  final UserProfileController controller;
  final int selectedTab;

  const UserProfileGrid({
    super.key,
    required this.controller,
    required this.selectedTab,
  });

  List<Post> _postsForTab() {
    return controller.getPostsForTab(selectedTab == 0 ? 0 : 2);
  }

  /// Enrich post with user profile data
  Post _enrichPostWithUserData(Post post) {
    final userProfile = controller.user;
    if (userProfile == null) return post;

    // Create a new Post with enriched user data
    return Post(
      id: post.id,
      caption: post.caption,
      media: post.media,
      mediaType: post.mediaType,
      userId: userProfile.id.isNotEmpty ? userProfile.id : post.userId,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      isLiked: post.isLiked,
      username: userProfile.username.isNotEmpty
          ? userProfile.username
          : post.username,
      isSubscribed: post.isSubscribed,
      profilePicture: userProfile.profileImage.isNotEmpty
          ? userProfile.profileImage
          : post.profilePicture,
      hasActiveStory: userProfile.hasActiveStory,
    );
  }

  Widget _buildGridLoadingPlaceholders({int itemCount = 6}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.white.withValues(alpha: 0.10),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _postsForTab();
    final tabIsLoading = controller.isLoadingTab(selectedTab == 0 ? 0 : 2);
    final totalPostsCount = controller.statsNotifier.value.videosCount;

    if (totalPostsCount == 0 || (posts.isEmpty && !tabIsLoading)) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: Colors.white,
              size: 34,
            ),
            SizedBox(height: 12),
            Text(
              'No posts yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty && tabIsLoading) {
      return _buildGridLoadingPlaceholders();
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
        // Enrich post with user profile data
        final enrichedPost = _enrichPostWithUserData(post);

        return GestureDetector(
          onTap: () {
            // Enrich all posts with user data
            final enrichedPosts =
                posts.map((p) => _enrichPostWithUserData(p)).toList();

            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return ProfilePostDetailScreen(
                    post: enrichedPost,
                    allPosts: enrichedPosts,
                    initialIndex: index,
                    isOwnProfile: false,
                  );
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: enrichedPost.isVideo
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
                : AppCachedImage(
                    imageUrl: post.media,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
