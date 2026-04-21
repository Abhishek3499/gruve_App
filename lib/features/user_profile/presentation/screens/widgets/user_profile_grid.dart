import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_profile/controller/user_profile_controller.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';

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
        return ClipRRect(
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
        );
      },
    );
  }
}
