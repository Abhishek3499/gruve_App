import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_controller_notifier.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_state_notifier.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_controller_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_state_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_views_notifier.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/more_screen.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_view_topbar/highlight_sheet.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_view_topbar/story_viewers_sheet.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_playback_controller.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/story_settings_screen.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class StoryViewBottom extends ConsumerStatefulWidget {
  final bool isOwnProfile;

  const StoryViewBottom({super.key, this.isOwnProfile = false});

  @override
  ConsumerState<StoryViewBottom> createState() => _StoryViewBottomState();
}

class _StoryViewBottomState extends ConsumerState<StoryViewBottom> {
  HighlightModel? _matchedHighlight;
  bool _isPreparingHighlight = false;
  static const Color _inactiveColor = Colors.white;
  static const Color _selectedColor = AppColors.success;
  static const double _highlightIconSize = 24;

  @override
  void initState() {
    super.initState();

    // Only fetch highlights/views for own profile
    if (widget.isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final highlightState = ref.read(highlightControllerProvider);
        if (highlightState.highlights.isEmpty && !highlightState.isLoading) {
          ref.read(highlightControllerProvider.notifier).fetchMyHighlights();
        }
        _fetchViewsForCurrentStory();
      });
    }

    AppLogger.d(
      '[StoryViewBottom] initState - isOwnProfile: ${widget.isOwnProfile}',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onStoryChanged() {
    if (mounted && _matchedHighlight != null) {
      setState(() {
        _matchedHighlight = null;
      });
    }
  }

  void _onCurrentStoryChanged() {
    _onStoryChanged();
    _fetchViewsForCurrentStory();
  }

  void _fetchViewsForCurrentStory() {
    if (!widget.isOwnProfile) return;
    final storyId = ref.read(storyStateNotifierProvider).currentStory?.id;
    if (storyId == null || storyId.isEmpty) return;
    ref.read(storyViewsNotifierProvider.notifier).fetchViews(storyId);
  }

  Widget _buildHighlightIcon({
    required bool isHighlighted,
    required Color color,
  }) {
    if (_isPreparingHighlight) {
      return const SizedBox(
        key: ValueKey('highlight-loading'),
        width: _highlightIconSize,
        height: _highlightIconSize,
        child: CircularProgressIndicator(
          color: AppColors.loaderDark,
          strokeWidth: 2,
        ),
      );
    }

    if (isHighlighted) {
      return Icon(
        Icons.favorite,
        key: const ValueKey('highlight-filled-heart'),
        color: color,
        size: _highlightIconSize,
      );
    }

    return Icon(
      isHighlighted ? Icons.favorite : Icons.favorite_border,
      color: color,
      size: 24,
    );
  }

  Future<String?> _resolveCurrentStoryId() async {
    final storyState = ref.read(storyStateNotifierProvider);
    final currentStory = storyState.currentStory;
    final currentId = currentStory?.id.trim();
    if (currentId != null && currentId.isNotEmpty) return currentId;

    if (currentStory == null) return null;

    AppLogger.d('[HighlightButton] Resolving missing story id');
    final storyController = ref.read(storyControllerProvider.notifier);
    await storyController.fetchStories(userId: null);

    if (!storyController.isSuccess || storyController.stories.isEmpty) {
      return null;
    }

    await ref
        .read(storyStateNotifierProvider.notifier)
        .setStoriesFromStoryItems(
          storyController.stories,
          username: storyState.username,
          avatarUrl: storyState.avatarUrl,
          userId: null,
        );

    final refreshedStory = _matchRefreshedStory(
      currentStory,
      storyController.stories,
    );

    if (refreshedStory == null || refreshedStory.id.trim().isEmpty) {
      return null;
    }

    ref
        .read(storyStateNotifierProvider.notifier)
        .setCurrentStory(refreshedStory);
    return refreshedStory.id;
  }

  StoryItem? _matchRefreshedStory(
    StoryItem currentStory,
    List<StoryItem> refreshedStories,
  ) {
    for (final story in refreshedStories) {
      if (story.mediaUrl == currentStory.mediaUrl) return story;
    }

    final localMedia = currentStory.mediaUrl.split('/').last.toLowerCase();
    for (final story in refreshedStories) {
      if (localMedia.isNotEmpty &&
          story.mediaUrl.toLowerCase().contains(localMedia)) {
        return story;
      }
    }

    return refreshedStories.isEmpty ? null : refreshedStories.first;
  }

  Future<void> _handleHighlightTap(bool isHighlighted) async {
    if (_isPreparingHighlight) return;

    if (isHighlighted) {
      final highlightName = _matchedHighlight?.title;
      AppLogger.d(
        '[HighlightButton] Tap ignored: already added'
        '${highlightName == null ? '' : ' to $highlightName'}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already added to highlights'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isPreparingHighlight = true);

    try {
      final storyId = await _resolveCurrentStoryId();
      if (!mounted) return;

      if (storyId == null || storyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story is still syncing. Please try again shortly.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      AppLogger.d('[HighlightButton] Opening highlight sheet');
      showInstagramHighlightSheet(context);
    } catch (e) {
      AppLogger.d('[HighlightButton] Failed to prepare highlight sheet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open highlights right now'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPreparingHighlight = false);
      }
    }
  }

  /// Build the Highlight button (only shown for own profile)
  Widget _buildHighlightButton() {
    if (!widget.isOwnProfile) {
      AppLogger.d(
        '[StoryViewBottom] Highlight button hidden - not own profile',
      );
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        final currentStoryId = ref.watch(
          storyStateNotifierProvider.select((s) => s.currentStory?.id),
        );
        final isHighlighted =
            currentStoryId != null &&
            ref.watch(
              highlightStateNotifierProvider.select(
                (s) => s.isStoryHighlighted(currentStoryId),
              ),
            );
        final buttonColor = isHighlighted ? _selectedColor : _inactiveColor;

        AppLogger.d(
          '[HighlightButton] isOwnProfile: ${widget.isOwnProfile}, '
          'isHighlighted: $isHighlighted, storyId: ${currentStoryId ?? 'null'}',
        );

        return GestureDetector(
          onTap: () => _handleHighlightTap(isHighlighted),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildHighlightIcon(
                  isHighlighted: isHighlighted,
                  color: buttonColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(color: buttonColor, fontSize: 12),
                child: const Text('Highlight'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StoryItem?>(
      storyStateNotifierProvider.select((s) => s.currentStory),
      (previous, next) {
        if (previous?.id != next?.id || previous?.mediaUrl != next?.mediaUrl) {
          _onCurrentStoryChanged();
        }
      },
    );
    ref.listen<Set<String>>(
      highlightStateNotifierProvider.select((s) => s.highlightedStoryIds),
      (previous, next) {
        if (!setEquals(previous, next)) {
          _onStoryChanged();
        }
      },
    );

    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Viewers button (eye icon + count) - only visible for own profile
          if (widget.isOwnProfile) _buildViewersButton() else const SizedBox(),
          Row(
            children: [
              // Highlight button - only visible for own profile
              _buildHighlightButton(),
              // Only add spacing if highlight button is shown
              if (widget.isOwnProfile) const SizedBox(width: 30),
              GestureDetector(
                onTap: () {
                  final playbackController = StoryPlaybackController();
                  playbackController.pauseStory(reason: 'More Options Open');

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.black54,
                    builder: (_) => const MoreScreen(),
                  ).then((result) async {
                    if (!context.mounted) return;
                    if (result == 'settings') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StorySettingsScreen(),
                        ),
                      );
                      playbackController.resumeStory(
                        reason: 'Settings Screen Closed',
                      );
                    } else if (result == 'highlight') {
                      if (!context.mounted) return;
                      showInstagramHighlightSheet(context);
                    } else {
                      playbackController.resumeStory(
                        reason: 'More Options Closed',
                      );
                    }
                  });
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.more_horiz, color: Colors.white),
                    SizedBox(height: 4),
                    Text('More', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Eye icon + views count - only visible for own profile. Tapping opens
  /// the Instagram-style "seen by" sheet for the current story.
  Widget _buildViewersButton() {
    return Builder(
      builder: (context) {
        final currentStoryId = ref.watch(
          storyStateNotifierProvider.select((s) => s.currentStory?.id),
        );
        final viewsCount = ref.watch(
          storyViewsNotifierProvider.select((s) => s.viewsCount),
        );

        return GestureDetector(
          onTap: () {
            if (currentStoryId == null || currentStoryId.isEmpty) return;
            showStoryViewersSheet(context, currentStoryId);
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white70,
                size: 18,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$viewsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
