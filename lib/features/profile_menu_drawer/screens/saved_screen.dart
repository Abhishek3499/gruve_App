import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/saved/saved_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/screens/post_detail_screen.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SavePostProvider>().fetchSavedPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _SavedScreenContent();
  }
}

class _SavedScreenContent extends StatelessWidget {
  const _SavedScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 71, 18, 86),
              Color.fromARGB(255, 6, 1, 7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SavedHeader(),
              SizedBox(height: context.rh(20)),
              Expanded(
                child: Consumer<SavePostProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoadingSavedPosts) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (provider.savedPostsError != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white70,
                              size: context.rw(48),
                            ),
                            SizedBox(height: context.rh(16)),
                            Text(
                              provider.savedPostsError!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.rf(16),
                              ),
                            ),
                            SizedBox(height: context.rh(16)),
                            ElevatedButton(
                              onPressed: () {
                                provider.fetchSavedPosts();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (provider.savedPostsList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: context.rw(64),
                            ),
                            SizedBox(height: context.rh(16)),
                            Text(
                              'No saved posts yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: context.rf(18),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: context.rh(8)),
                            Text(
                              'Save posts to view them here',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: context.rf(14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.all(context.rw(16)),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: provider.savedPostsList.length,
                      itemBuilder: (context, index) {
                        final post = provider.savedPostsList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                      return PostDetailScreen(
                                        post: post,
                                        allPosts: provider.savedPostsList,
                                        initialIndex: index,
                                      );
                                    },
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.black26,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  post.media.isEmpty
                                      ? Container(
                                          color: Colors.grey[900],
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.white54,
                                            size: context.rw(32),
                                          ),
                                        )
                                      : Image.network(
                                          post.media,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[900],
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white54,
                                                    size: context.rw(32),
                                                  ),
                                                );
                                              },
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  color: Colors.grey[900],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white54,
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                );
                                              },
                                        ),
                                  if (post.isVideo)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(context.rw(4)),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: context.rw(16),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: context.rw(14),
                                        ),
                                        SizedBox(width: context.rw(4)),
                                        Text(
                                          '${post.likesCount}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.rf(12),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
