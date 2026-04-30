import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_profile/controller/user_profile_controller.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/profile/screens/post_detail/profile_post_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final posts = _postsForTab();

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
            child: post.media.toLowerCase().contains('.mp4')
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
          ),
        );
      },
    );
  }
}
