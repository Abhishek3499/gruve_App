import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/data/controller/user_profile_controller.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/profile/screens/post_detail/profile_post_detail_screen.dart';
import 'package:gruve_app/core/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/core/widgets/profile_grid_style.dart';
import 'package:gruve_app/core/widgets/shimmer/profile_shimmer.dart';

class UserProfileGrid extends StatelessWidget {
  static const gridDelegate = ProfileGridStyle.gridDelegate;
  static const gridPadding = ProfileGridStyle.gridPadding;

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

    return Post(
      id: post.id,
      caption: post.caption,
      media: post.media,
      thumbnailUrl: post.thumbnailUrl,
      mediaType: post.mediaType,
      userId: userProfile.id.isNotEmpty ? userProfile.id : post.userId,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      sharesCount: post.sharesCount,
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

  Widget _buildEmptyState() {
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

  Widget _buildLoadingSliverGrid() {
    return const SliverToBoxAdapter(
      child: ProfileGridShimmer(itemCount: 6),
    );
  }

  List<Widget> _buildPostsSlivers(List<Post> posts, BuildContext context) {
    return [
      SliverPadding(
        padding: gridPadding,
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              final enrichedPost = _enrichPostWithUserData(post);

              return GestureDetector(
                onTap: () => _openPost(
                  context,
                  enrichedPost,
                  posts.map((p) => _enrichPostWithUserData(p)).toList(),
                  index,
                ),
                child: ProfileGridTile(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PostGridThumbnail(post: enrichedPost),
                    if (enrichedPost.isVideo)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: posts.length,
          ),
        ),
      ),
    ];
  }

  /// Sliver-based grid for use inside [CustomScrollView].
  List<Widget> buildSlivers(BuildContext context) {
    final posts = _postsForTab();
    final tabIsLoading = controller.isLoadingTab(selectedTab == 0 ? 0 : 2);
    final totalPostsCount = controller.statsNotifier.value.videosCount;

    if (totalPostsCount == 0 || (posts.isEmpty && !tabIsLoading)) {
      return [SliverToBoxAdapter(child: _buildEmptyState())];
    }

    if (posts.isEmpty && tabIsLoading) {
      return [_buildLoadingSliverGrid()];
    }

    return _buildPostsSlivers(posts, context);
  }

  bool _hasPlayableVideo(Post post) {
    final media = post.media.trim();
    return post.isVideo &&
        media.isNotEmpty &&
        (media.startsWith('http://') || media.startsWith('https://'));
  }

  Future<Post?> _resolvePostMedia(Post preview) async {
    if (preview.id.isEmpty) return null;
    try {
      final fetched = await PostService().fetchPostById(preview.id);
      return preview.mergedWith(other: fetched);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openPost(
    BuildContext context,
    Post post,
    List<Post> allPosts,
    int index,
  ) async {
    final needsResolve = post.isVideo
        ? !_hasPlayableVideo(post)
        : post.media.trim().isEmpty;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfilePostDetailScreen(
            post: post,
            allPosts: allPosts,
            initialIndex: index,
            isOwnProfile: false,
            onResolveMedia: needsResolve
                ? () => _resolvePostMedia(post)
                : null,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      slivers: buildSlivers(context),
    );
  }
}
