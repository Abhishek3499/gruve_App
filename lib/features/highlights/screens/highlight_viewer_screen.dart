import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:provider/provider.dart';

class HighlightViewerScreen extends StatefulWidget {
  final String highlightId;

  const HighlightViewerScreen({super.key, required this.highlightId});

  @override
  State<HighlightViewerScreen> createState() => _HighlightViewerScreenState();
}

class _HighlightViewerScreenState extends State<HighlightViewerScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool isLoading = true;
  String? errorMessage;
  HighlightModel? highlight;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onProgressStatusChanged);
    debugPrint('[Viewer] Opened with highlight ID: ${widget.highlightId}');
    _fetchHighlight();
  }

  @override
  void dispose() {
    _progressController
      ..removeStatusListener(_onProgressStatusChanged)
      ..dispose();
    super.dispose();
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _nextStory();
    }
  }

  void _restartProgress() {
    if (!mounted || highlight == null || highlight!.stories.isEmpty) return;
    _progressController
      ..reset()
      ..forward();
  }

  Future<void> _fetchHighlight() async {
    debugPrint('[Viewer] Fetch start');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint(
        '[API] Fetching highlight stories for ID: ${widget.highlightId}',
      );

      final highlightController = context.read<HighlightController>();

      final fetchedHighlight = await highlightController.fetchHighlightStories(
        widget.highlightId,
      );

      if (fetchedHighlight != null) {
        setState(() {
          isLoading = false;
          highlight = fetchedHighlight;
          debugPrint(
            '[Viewer] API success - Stories count: ${highlight!.stories.length}',
          );
        });
        _restartProgress();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Highlight stories not found';
          debugPrint('[Viewer] API failed: Highlight stories not found');
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load highlight stories: $e';
        debugPrint('[Viewer] API failed: $e');
      });
    }
  }

  void _nextStory() {
    if (highlight == null) return;

    if (currentIndex < highlight!.stories.length - 1) {
      setState(() {
        currentIndex++;
        debugPrint('[Viewer] Current index: $currentIndex');
      });
      _restartProgress();
    } else {
      // Last story, close the viewer
      debugPrint('[Viewer] Last story reached, closing');
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        debugPrint('[Viewer] Current index: $currentIndex');
      });
      _restartProgress();
    }
  }

  void _handleTap(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx > width / 2) {
      _nextStory();
    } else {
      _previousStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          if (isLoading)
            _buildLoadingState()
          else if (errorMessage != null)
            _buildErrorState()
          else if (highlight == null || highlight!.stories.isEmpty)
            _buildEmptyState()
          else
            _buildStoryViewer(),

          _buildTopOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const _HighlightLoader();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchHighlight,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text(
            'No stories available',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryViewer() {
    final story = highlight!.stories[currentIndex];

    return GestureDetector(
      onTapUp: _handleTap,
      onLongPressStart: (_) => _progressController.stop(),
      onLongPressEnd: (_) => _progressController.forward(),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _previousStory();
        } else if (details.primaryVelocity! < 0) {
          _nextStory();
        }
      },
      child: Center(child: _buildStoryMedia(story)),
    );
  }

  Widget _buildStoryMedia(HighlightStoryRef story) {
    if (story.mediaUrl.toLowerCase().endsWith('.mp4') ||
        story.mediaUrl.toLowerCase().endsWith('.mov')) {
      // Video placeholder
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
        ),
      );
    } else {
      // Image
      return Image.network(
        story.mediaUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const _HighlightLoader();
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 64),
          );
        },
      );
    }
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLoading &&
                errorMessage == null &&
                highlight != null &&
                highlight!.stories.isNotEmpty)
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return _InstagramHighlightProgress(
                    storyCount: highlight!.stories.length,
                    currentIndex: currentIndex,
                    progress: _progressController.value,
                  );
                },
              )
            else
              const SizedBox(height: 2.6),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    debugPrint('[Viewer] Back button pressed');
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (highlight != null)
                  Expanded(
                    child: Text(
                      highlight!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InstagramHighlightProgress extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final double progress;

  const _InstagramHighlightProgress({
    required this.storyCount,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final count = storyCount <= 0 ? 1 : storyCount;

    return Row(
      children: List.generate(count, (index) {
        final fill = index < currentIndex
            ? 1.0
            : index == currentIndex
            ? progress.clamp(0.0, 1.0)
            : 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 2,
              right: index == count - 1 ? 0 : 2,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 2.6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HighlightLoader extends StatelessWidget {
  const _HighlightLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: AppColors.loaderDark,
          strokeWidth: 2.6,
        ),
      ),
    );
  }
}
