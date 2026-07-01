import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:video_player/video_player.dart';

class HighlightViewerScreen extends StatefulWidget {
  final String highlightId;
  final HighlightModel? initialHighlight;

  const HighlightViewerScreen({
    super.key,
    required this.highlightId,
    this.initialHighlight,
  });

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
  HighlightController? _highlightController;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onProgressStatusChanged);
    AppLogger.d('[Viewer] Opened with highlight ID: ${widget.highlightId}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _highlightController ??= context.read<HighlightController>();
    if (_bootstrapped) return;
    _bootstrapped = true;

    final highlightController = _highlightController!;
    final cached =
        widget.initialHighlight ??
        highlightController.cachedHighlightStories(widget.highlightId);

    if (cached != null && cached.stories.isNotEmpty) {
      highlight = cached;
      isLoading = false;
      highlightController.cacheHighlightStories(cached);
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartProgress());
      _fetchHighlight(background: true);
    } else {
      _fetchHighlight();
    }
  }

  @override
  void dispose() {
    _progressController
      ..removeStatusListener(_onProgressStatusChanged)
      ..dispose();
    _highlightController?.cancelActiveRequests();
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

  Future<void> _fetchHighlight({bool background = false}) async {
    AppLogger.d('[Viewer] Fetch start (background=$background)');
    if (!background) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final highlightController = _highlightController;
      if (highlightController == null) return;

      final fetchedHighlight = await highlightController.fetchHighlightStories(
        widget.highlightId,
      );

      if (fetchedHighlight != null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          highlight = fetchedHighlight;
          if (currentIndex >= highlight!.stories.length) {
            currentIndex = 0;
          }
          AppLogger.d(
            '[Viewer] API success - Stories count: ${highlight!.stories.length}',
          );
        });
        _restartProgress();
      } else if (!background) {
        setState(() {
          isLoading = false;
          errorMessage = 'Highlight stories not found';
          AppLogger.d('[Viewer] API failed: Highlight stories not found');
        });
      }
    } catch (e) {
      if (!background && mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load highlight stories: $e';
          AppLogger.d('[Viewer] API failed: $e');
        });
      }
    }
  }

  void _showMoreOptions() {
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: const ui.Color.fromARGB(220, 33, 19, 44),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Delete Highlight',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted && highlight != null) {
        _progressController.forward();
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF321344), Color(0xFF161626)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFD42BC2).withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD42BC2).withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Highlight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "${highlight?.title}"? This action cannot be undone.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Keep it',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _performDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performDelete() async {
    if (highlight == null) return;

    setState(() {
      isLoading = true;
    });

    final highlightController = context.read<HighlightController>();
    final success = await highlightController.deleteHighlight(widget.highlightId);

    if (success) {
      if (mounted) {
        context.read<ProfileProvider>().removeHighlightLocally(widget.highlightId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('"${highlight?.title}" deleted successfully.'),
              ],
            ),
            backgroundColor: const Color(0xFF8B25C6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to delete highlight. Please try again.'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }

  void _nextStory() {
    if (highlight == null) return;

    if (currentIndex < highlight!.stories.length - 1) {
      setState(() {
        currentIndex++;
        AppLogger.d('[Viewer] Current index: $currentIndex');
      });
      _restartProgress();
    } else {
      // Last story, close the viewer
      AppLogger.d('[Viewer] Last story reached, closing');
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        AppLogger.d('[Viewer] Current index: $currentIndex');
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
      child: Center(
        child: _HighlightStoryMedia(
          key: ValueKey(story.id),
          story: story,
          onVideoDurationResolved: (duration) {
            if (!mounted || duration <= Duration.zero) return;
            _progressController.duration = duration;
            _restartProgress();
          },
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    if (isLoading) return const SizedBox.shrink();
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
                BackButton(
                  color: Colors.white,
                  onPressed: () {
                    AppLogger.d('[Viewer] Back button pressed');
                    Navigator.of(context).pop();
                  },
                ),
                if (highlight != null) ...[
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
                  ),
                  IconButton(
                    onPressed: _showMoreOptions,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
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

class _HighlightStoryMedia extends StatefulWidget {
  final HighlightStoryRef story;
  final ValueChanged<Duration>? onVideoDurationResolved;

  const _HighlightStoryMedia({
    super.key,
    required this.story,
    this.onVideoDurationResolved,
  });

  @override
  State<_HighlightStoryMedia> createState() => _HighlightStoryMediaState();
}

class _HighlightStoryMediaState extends State<_HighlightStoryMedia> {
  VideoPlayerController? _videoController;
  bool _videoFailed = false;

  String get _mediaUrl {
    final preview = widget.story.previewUrl;
    if (preview != null && preview.isNotEmpty) return preview;
    return widget.story.mediaUrl.trim();
  }

  bool get _isVideo => Post.mediaUrlLooksLikeVideo(_mediaUrl);

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _HighlightStoryMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story.id != widget.story.id ||
        oldWidget.story.mediaUrl != widget.story.mediaUrl) {
      _disposeVideo();
      _videoFailed = false;
      if (_isVideo) {
        _initVideo();
      }
    }
  }

  Future<void> _initVideo() async {
    final url = _mediaUrl;
    if (!MediaUrlThumbnail.isHttpUrl(url)) {
      if (mounted) setState(() => _videoFailed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _videoController = controller);
      widget.onVideoDurationResolved?.call(controller.value.duration);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      if (_videoFailed) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 64),
        );
      }

      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const _HighlightLoader();
      }

      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    final imageUrl = _mediaUrl;
    if (!MediaUrlThumbnail.isHttpUrl(imageUrl)) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 64),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (context, url) => const _HighlightLoader(),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 64),
      ),
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
