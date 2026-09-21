import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_controller_notifier.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_state_notifier.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_flow_notifier.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_create_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_state_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_playback_controller.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_view_topbar/story_selector_screen.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/shared/widgets/app_cached_image.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_share_flow_bridge.dart';

void _log(String message) {
  AppLogger.d(message);
}

void showInstagramHighlightSheet(BuildContext context) {
  final playbackController = StoryPlaybackController();
  final container = ProviderScope.containerOf(context, listen: false);
  final currentStory = container.read(storyStateNotifierProvider).currentStory;

  _log('[HighlightSheet] Opening sheet -> Pause Story');

  _log(
    '[HighlightSheet] Current story when opening sheet: '
    '${currentStory?.id ?? 'NULL'}',
  );

  if (currentStory == null) {
    _log('[HighlightSheet] ERROR: cannot open sheet without currentStory');
    return;
  }

  if (currentStory.id.isEmpty) {
    _log('[HighlightSheet] ERROR: cannot open sheet with empty story id');
    return;
  }

  playbackController.pauseStory(reason: 'Highlight Sheet Open');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const HighlightSheetContent(),
  ).then((_) {
    _log('[HighlightSheet] Sheet closed -> Resume Story');
    playbackController.resumeStory(reason: 'Highlight Sheet Closed');

    container.read(highlightControllerProvider.notifier).fetchMyHighlights();
  });
}

class HighlightSheetContent extends ConsumerStatefulWidget {
  const HighlightSheetContent({super.key});

  @override
  ConsumerState<HighlightSheetContent> createState() =>
      _HighlightSheetContentState();
}

class _HighlightSheetContentState extends ConsumerState<HighlightSheetContent> {
  int selectedIndex = -1;
  bool _isLoadingHighlights = true;

  @override
  void initState() {
    super.initState();
    _log('[HighlightSheet] initState - Fetching highlights');

    final currentStory = ref.read(storyStateNotifierProvider).currentStory;
    _log(
      '[HighlightSheet] Current story on init: ${currentStory?.id ?? 'NULL'}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchHighlights();
      }
    });
  }

  Future<void> _fetchHighlights() async {
    if (!mounted) return;
    setState(() => _isLoadingHighlights = true);

    await ref.read(highlightControllerProvider.notifier).fetchMyHighlights();

    if (!mounted) return;
    setState(() => _isLoadingHighlights = false);
  }

  bool _isStoryAlreadyAdded(HighlightModel highlight) {
    final currentStory = ref.read(storyStateNotifierProvider).currentStory;
    if (currentStory == null || currentStory.id.isEmpty) return false;
    return highlight.containsStory(currentStory.id);
  }

  bool _isSelectedStoryAlreadyAdded() {
    final highlights = ref.read(highlightControllerProvider).highlights;
    if (selectedIndex < 0 || selectedIndex >= highlights.length) {
      return false;
    }

    return _isStoryAlreadyAdded(highlights[selectedIndex]);
  }

  Future<void> _handleDonePressed() async {
    final isProcessing = ref.read(highlightFlowNotifierProvider);

    if (isProcessing) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    ref.read(highlightFlowNotifierProvider.notifier).setProcessing(true);

    final currentStory = ref.read(storyStateNotifierProvider).currentStory;
    final highlights = ref.read(highlightControllerProvider).highlights;
    final highlight = selectedIndex >= 0 && selectedIndex < highlights.length
        ? highlights[selectedIndex]
        : null;

    _log('[Flow] Start Add to Highlight');
    _log('[Flow] Story ID: ${currentStory?.id}');
    _log('[Flow] Highlight ID: ${highlight?.id}');

    try {
      if (currentStory == null) {
        _log('[Flow] ERROR: currentStory is null');
        return;
      }

      if (currentStory.id.isEmpty) {
        _log('[HighlightSheet] ERROR: currentStory.id is empty');
        return;
      }

      if (highlight == null) {
        _log(
          '[HighlightSheet] Invalid index: $selectedIndex, highlights count: '
          '${highlights.length}',
        );
        return;
      }

      await ref
          .read(highlightCreateNotifierProvider.notifier)
          .addStoryToHighlight(
            highlightId: highlight.id,
            storyId: currentStory.id,
          );

      final createState = ref.read(highlightCreateNotifierProvider);

      if (createState.isSuccess) {
        _log('[Flow] API SUCCESS');

        await ref
            .read(highlightStateNotifierProvider.notifier)
            .addHighlightedStory(currentStory.id);

        if (!mounted) return;

        sheetNavigator.pop();

        _log('[Flow] Navigation triggered');
        PostShareFlowBridge.onRequestShowProfileTab?.call();
        rootNavigator.pop();
      } else {
        _log('[Flow] API FAILED');
        if (mounted && createState.message.isNotEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(createState.message)),
          );
        }
      }
    } finally {
      ref.read(highlightFlowNotifierProvider.notifier).setProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(highlightFlowNotifierProvider);
    final highlights = ref.watch(
      highlightControllerProvider.select((state) => state.highlights),
    );

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Add to highlights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 250,
                child: _isLoadingHighlights
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: AppColors.loaderPrimary,
                            strokeWidth: 2.4,
                          ),
                        ),
                      )
                    : _buildHighlightsList(highlights),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: selectedIndex != -1 ? 80 : 30,
                child: selectedIndex != -1
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSelectedStoryAlreadyAdded()
                              ? null
                              : _handleDonePressed,
                          child: Text(
                            _isSelectedStoryAlreadyAdded()
                                ? 'Already added'
                                : 'Done',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.loaderDark,
                    strokeWidth: 2.4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightsList(List<HighlightModel> highlights) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: highlights.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddButton();
        }

        final highlightIndex = index - 1;
        final highlight = highlights[highlightIndex];
        final isSelected = selectedIndex == highlightIndex;
        final isAlreadyAdded = _isStoryAlreadyAdded(highlight);

        return GestureDetector(
          onTap: () {
            if (isAlreadyAdded) {
              _log(
                '[HighlightSheet] Duplicate detected: '
                'highlight_id=${highlight.id}, '
                'story_id=${ref.read(storyStateNotifierProvider).currentStory?.id}',
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Already added')));
            }

            _log('[HighlightSheet] Highlight tapped - selection only');
            setState(() {
              selectedIndex = isSelected ? -1 : highlightIndex;
            });
          },
          child: _buildHighlightThumbnail(highlight, isSelected),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              _log('[HighlightSheet] Navigating to CreateHighlightSheet');

              final currentStory = ref
                  .read(storyStateNotifierProvider)
                  .currentStory;

              if (currentStory == null) {
                _log('[HighlightSheet] ERROR: No story selected');
                return;
              }

              if (currentStory.id.isEmpty) {
                _log('[HighlightSheet] ERROR: currentStory.id is empty');
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateHighlightSheet(
                    storyImageUrl: currentStory.mediaUrl,
                    storyId: currentStory.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: const Icon(Icons.add, size: 40, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'New',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightThumbnail(HighlightModel highlight, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          AnimatedScale(
            scale: isSelected ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 180,
                    width: 130,
                    color: Colors.grey[300],
                    child: highlight.coverMediaUrl.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: highlight.coverMediaUrl,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.collections),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    height: 180,
                    width: 130,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(highlight.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
