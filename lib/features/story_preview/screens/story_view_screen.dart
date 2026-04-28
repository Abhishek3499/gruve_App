import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_view_bottom.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_viewer_topbar.dart';
import 'package:gruve_app/features/story_preview/controllers/story_playback_controller.dart';

class StoryViewScreen extends StatefulWidget {
  final String? userId;
  final List<String> mediaPaths;
  final String displayName;
  final String username;
  final String avatarUrl;
  final List<DateTime>? timestamps;

  const StoryViewScreen({
    super.key,
    this.userId,
    required this.mediaPaths,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
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
  bool _isDisposed = false;
  AnimationStatusListener? _animationListener;
  
  // Global playback controller
  final StoryPlaybackController _playbackController = StoryPlaybackController();

  @override
  void initState() {
    super.initState();

    // Initialize global playback controller
    _playbackController.initialize();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Add status listener once
    _animationListener = (status) {
      if (status == AnimationStatus.completed && !_isDisposed && !_playbackController.isPaused) {
        nextStory();
      }
    };
    _animationController.addStatusListener(_animationListener!);

    // Listen to playback controller changes
    _playbackController.addListener(_onPlaybackStateChanged);

    // Initialize media immediately without blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMedia();
    });
  }

  // Handle playback state changes from global controller
  void _onPlaybackStateChanged() {
    if (_isDisposed) return;
    
    if (_playbackController.isPaused) {
      _pauseAnimationAndVideo();
    } else {
      _resumeAnimationAndVideo();
    }
  }

  // ✅ MEDIA INIT
  Future<void> _initializeMedia() async {
    if (_isDisposed) return;
    
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

      if (_isDisposed) {
        _videoController?.dispose();
        return;
      }

      _videoController!.play();
      _videoController!.setLooping(true);

      // ✅ sync animation with video duration
      _animationController.duration = _videoController!.value.duration;
    } else {
      _animationController.duration = const Duration(seconds: 5);
    }

    // Only start animation if not paused
    if (!_playbackController.isPaused) {
      _animationController.forward(from: 0);
    }

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  // ✅ NEXT
  void nextStory() {
    if (_isDisposed) return;
    
    if (currentIndex < widget.mediaPaths.length - 1) {
      setState(() => currentIndex++);
      _initializeMedia();
    } else {
      // Navigate back when last story ends
      if (mounted && !_isDisposed) {
        Navigator.pop(context);
      }
    }
  }

  // ✅ PREVIOUS
  void previousStory() {
    if (_isDisposed) return;
    
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
    _playbackController.pauseStory(reason: "Long Press");
  }

  // ✅ RESUME
  void _resumeStory() {
    _playbackController.resumeStory(reason: "Long Press Release");
  }

  // Internal pause for animation and video
  void _pauseAnimationAndVideo() {
    _animationController.stop();
    _videoController?.pause();
  }

  // Internal resume for animation and video
  void _resumeAnimationAndVideo() {
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
    _isDisposed = true;
    _playbackController.removeListener(_onPlaybackStateChanged);
    _playbackController.reset();
    _videoController?.dispose();
    if (_animationListener != null) {
      _animationController.removeStatusListener(_animationListener!);
    }
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildMedia() {
    final path = widget.mediaPaths[currentIndex];

    // VIDEO
    if (_isVideo && _videoController != null) {
      if (!_videoController!.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
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
      return Image.network(
        path, 
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(path), 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPressStart: (details) {
          debugPrint("👆 [StoryViewScreen] Long Press Detected");
          _pauseStory();
        },
        onLongPressEnd: (details) {
          debugPrint("👆 [StoryViewScreen] Long Press Released");
          _resumeStory();
        },
        onHorizontalDragEnd: _handleSwipe,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMedia()),

            StoryViewerTopBar(
              username: widget.displayName.isNotEmpty ? widget.displayName : "User",
              time: _getCurrentStoryTime(),
              avatarUrl: widget.avatarUrl.isNotEmpty
                  ? widget.avatarUrl
                  : "https://i.pravatar.cc/150?img=3",
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
