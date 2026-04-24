import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_view_bottom.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_viewer_topbar.dart';

class StoryViewScreen extends StatefulWidget {
  final List<String> mediaPaths;
  final String? username;
  final String? avatarUrl;
  final List<DateTime>? timestamps;

  const StoryViewScreen({
    super.key,
    required this.mediaPaths,
    this.username,
    this.avatarUrl,
    this.timestamps,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addListener(() {
      setState(() {});
    });

    _initializeMedia();
  }

  // ✅ MEDIA INIT
  Future<void> _initializeMedia() async {
    _videoController?.dispose();
    _videoController = null;

    String mediaPath = widget.mediaPaths[currentIndex];

    _isVideo =
        mediaPath.toLowerCase().endsWith(".mp4") ||
        mediaPath.toLowerCase().endsWith(".mov") ||
        mediaPath.toLowerCase().endsWith(".avi");

    if (_isVideo) {
      if (mediaPath.startsWith("http")) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(mediaPath),
        );
      } else {
        _videoController = VideoPlayerController.file(File(mediaPath));
      }

      await _videoController!.initialize();

      _videoController!.play();
      _videoController!.setLooping(true);

      // ✅ sync animation with video duration
      _animationController.duration = _videoController!.value.duration;
    } else {
      _animationController.duration = const Duration(seconds: 5);
    }

    _animationController.forward(from: 0);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        nextStory();
      }
    });

    setState(() {});
  }

  // ✅ NEXT
  void nextStory() {
    if (currentIndex < widget.mediaPaths.length - 1) {
      setState(() => currentIndex++);
      _initializeMedia();
    } else {
      Navigator.pop(context);
    }
  }

  // ✅ PREVIOUS
  void previousStory() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _initializeMedia();
    }
  }

  // ✅ TAP
  void _handleTap(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;

    if (details.globalPosition.dx > width / 2) {
      nextStory();
    } else {
      previousStory();
    }
  }

  // ✅ HOLD PAUSE
  void _pauseStory() {
    _animationController.stop();
    _videoController?.pause();
  }

  // ✅ RESUME
  void _resumeStory() {
    _animationController.forward();
    _videoController?.play();
  }

  // ✅ SWIPE
  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < 0) {
      nextStory();
    } else if (velocity > 0) {
      previousStory();
    }
  }

  String _getCurrentStoryTime() {
    if (widget.timestamps != null && currentIndex < widget.timestamps!.length) {
      final diff = DateTime.now().difference(widget.timestamps![currentIndex]);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return '4h';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildMedia() {
    final path = widget.mediaPaths[currentIndex];

    // VIDEO
    if (_isVideo && _videoController != null) {
      if (!_videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // IMAGE
    if (path.startsWith("http")) {
      return Image.network(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPress: _pauseStory,
        onLongPressUp: _resumeStory,
        onHorizontalDragEnd: _handleSwipe,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMedia()),

            StoryViewerTopBar(
              username: widget.username ?? "Username",
              time: _getCurrentStoryTime(),
              avatarUrl: widget.avatarUrl ?? "https://i.pravatar.cc/150?img=3",
              storyCount: widget.mediaPaths.length,
              currentIndex: currentIndex,
              progress: _animationController.value,
              onClose: () => Navigator.pop(context),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(top: false, child: const StoryViewBottom()),
            ),
          ],
        ),
      ),
    );
  }
}
