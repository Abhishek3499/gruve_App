import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_playback_controller.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_views_notifier.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/features/story_preview/utils/story_utils.dart';
import 'package:gruve_app/shared/widgets/app_cached_image.dart';

/// Opens the Instagram-style "seen by" sheet for the currently active own
/// story. Assumes [StoryViewsNotifier] already holds (or is loading) the
/// viewers for [storyId] — the eye icon triggers the initial fetch.
void showStoryViewersSheet(BuildContext context, String storyId) {
  if (storyId.isEmpty) return;

  final playbackController = StoryPlaybackController();
  playbackController.pauseStory(reason: 'Story Viewers Sheet Open');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const StoryViewersSheetContent(),
  ).then((_) {
    playbackController.resumeStory(reason: 'Story Viewers Sheet Closed');
  });
}

class StoryViewersSheetContent extends ConsumerStatefulWidget {
  const StoryViewersSheetContent({super.key});

  @override
  ConsumerState<StoryViewersSheetContent> createState() =>
      _StoryViewersSheetContentState();
}

class _StoryViewersSheetContentState
    extends ConsumerState<StoryViewersSheetContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(storyViewsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyViewsNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.viewsCount} ${state.viewsCount == 1 ? 'view' : 'views'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.white24),
              Expanded(child: _buildBody(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(StoryViewsState state) {
    if (state.isLoading && state.viewers.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: AppColors.loaderPrimary,
            strokeWidth: 2.4,
          ),
        ),
      );
    }

    if (state.viewers.isEmpty) {
      return const Center(
        child: Text(
          'No views yet',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.viewers.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.viewers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.loaderPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final viewer = state.viewers[index];
        return _StoryViewerTile(viewer: viewer);
      },
    );
  }
}

class _StoryViewerTile extends StatelessWidget {
  final StoryViewer viewer;

  const _StoryViewerTile({required this.viewer});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = viewer.profilePicture?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: avatarUrl.startsWith('http')
                  ? AppCachedImage(
                      imageUrl: avatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      shape: BoxShape.circle,
                    )
                  : Image.asset('assets/profile.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewer.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            StoryUtils.getStoryTimeDisplay(viewer.viewedAt),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
