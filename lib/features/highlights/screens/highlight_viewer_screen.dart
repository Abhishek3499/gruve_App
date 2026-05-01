import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';

class HighlightViewerScreen extends StatefulWidget {
  final String highlightId;

  const HighlightViewerScreen({super.key, required this.highlightId});

  @override
  State<HighlightViewerScreen> createState() => _HighlightViewerScreenState();
}

class _HighlightViewerScreenState extends State<HighlightViewerScreen> {
  int currentIndex = 0;
  bool isLoading = true;
  String? errorMessage;
  HighlightModel? highlight;

  @override
  void initState() {
    super.initState();
    debugPrint('[Viewer] Opened with highlight ID: ${widget.highlightId}');
    _fetchHighlight();
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

      final highlightController = Get.isRegistered<HighlightController>()
          ? Get.find<HighlightController>()
          : Get.put(HighlightController());

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

          // Top overlay
          _buildTopOverlay(),

          // Bottom progress indicator
          if (!isLoading &&
              errorMessage == null &&
              highlight != null &&
              highlight!.stories.isNotEmpty)
            _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
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
      onTap: _nextStory,
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              debugPrint('[Viewer] Back button pressed');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          if (highlight != null)
            Expanded(
              child: Text(
                highlight!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          highlight!.stories.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: currentIndex == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
