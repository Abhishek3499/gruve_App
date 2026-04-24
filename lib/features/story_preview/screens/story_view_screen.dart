import 'dart:io';
import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_view_bottom.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_viewer_topbar.dart';
// 👈 tumhara bottom widget

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
    
    debugPrint("\n🎬 ===== STORY VIEW SCREEN INIT =====");
    debugPrint("📱 Media Paths: ${widget.mediaPaths}");
    debugPrint("👤 Username: ${widget.username ?? 'Not provided'}");
    debugPrint("🖼️ Avatar: ${widget.avatarUrl ?? 'Not provided'}");
    debugPrint("⏰ Timestamps: ${widget.timestamps?.length ?? 0} items");

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    /// 🔥 THIS LINE IS MUST
    _animationController.addListener(() {
      setState(() {});
    });

    startAnimation();

    _initializeMedia();
    
    debugPrint("✅ Story View Screen Initialized");
    debugPrint("🏁 ===== STORY VIEW SCREEN INIT END =====\n");
  }

  void _initializeMedia() {
    debugPrint("\n🎥 ===== INITIALIZING MEDIA =====");
    debugPrint("📊 Current Index: $currentIndex");
    
    // Dispose previous controller if exists
    _videoController?.dispose();
    _videoController = null;

    String mediaPath = widget.mediaPaths[currentIndex];
    debugPrint("📁 Media Path: $mediaPath");

    _isVideo =
        mediaPath.toLowerCase().endsWith(".mp4") ||
        mediaPath.toLowerCase().endsWith(".mov") ||
        mediaPath.toLowerCase().endsWith(".avi");

    debugPrint("🎬 Is Video: $_isVideo");

    if (_isVideo) {
      debugPrint("⏳ Initializing video controller...");
      _videoController = VideoPlayerController.file(File(mediaPath))
        ..initialize().then((_) {
          debugPrint("✅ Video initialized successfully");
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
          debugPrint("▶️ Video playing with loop");
        }).catchError((error) {
          debugPrint("❌ Video initialization failed: $error");
        });
    } else {
      debugPrint("🖼️ Loading image...");
      setState(() {});
    }
    
    debugPrint("🏁 ===== MEDIA INITIALIZATION END =====\n");
  }

  void startAnimation() {
    _animationController.forward();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        nextStory();
      }
    });
  }

  void nextStory() {
    debugPrint("\n⏭️ ===== NEXT STORY CALLED =====");
    debugPrint("📊 Current Index: $currentIndex");
    debugPrint("📱 Total Stories: ${widget.mediaPaths.length}");
    
    if (currentIndex < widget.mediaPaths.length - 1) {
      setState(() {
        currentIndex++;
      });
      debugPrint("➡️ Moved to story index: $currentIndex");

      // Reinitialize media for new story
      _initializeMedia();

      _animationController.reset();
      _animationController.forward();
      debugPrint("🔄 Animation restarted");
    } else {
      debugPrint("🚪 No more stories, closing screen");
      Navigator.pop(context);
    }
    
    debugPrint("🏁 ===== NEXT STORY END =====\n");
  }

  String _getCurrentStoryTime() {
    debugPrint("\n⏰ ===== CALCULATING STORY TIME =====");
    
    if (widget.timestamps != null && currentIndex < widget.timestamps!.length) {
      final timestamp = widget.timestamps![currentIndex];
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      debugPrint("📅 Story Time: $timestamp");
      debugPrint("⏱️ Time Difference: ${difference.inMinutes} minutes");
      
      String timeText;
      if (difference.inMinutes < 1) {
        timeText = 'Just now';
      } else if (difference.inHours < 1) {
        timeText = '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        timeText = '${difference.inHours}h ago';
      } else {
        timeText = '${difference.inDays}d ago';
      }
      
      debugPrint("🕐 Calculated Time: $timeText");
      debugPrint("🏁 ===== STORY TIME CALCULATION END =====\n");
      return timeText;
    }
    
    debugPrint("⚠️ No timestamp available, using fallback");
    debugPrint("🏁 ===== STORY TIME CALCULATION END =====\n");
    return '4h'; // Fallback
  }

  @override
  void dispose() {
    debugPrint("\n🗑️ ===== STORY VIEW SCREEN DISPOSE =====");
    debugPrint("🎬 Disposing video controller...");
    _videoController?.dispose();
    debugPrint("⏹️ Disposing animation controller...");
    _animationController.dispose();
    debugPrint("✅ Story View Screen disposed");
    debugPrint("🏁 ===== STORY VIEW SCREEN DISPOSE END =====\n");
    super.dispose();
  }

  Widget _buildMedia() {
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

    return Image.file(File(widget.mediaPaths[currentIndex]), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          /// MEDIA
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 70, // 👈 media bottom widget ke upar rukega
            child: _buildMedia(),
          ),

          /// TOP BAR
          StoryViewerTopBar(
            username: widget.username ?? "Username",
            time: _getCurrentStoryTime(),
            avatarUrl: widget.avatarUrl ?? "https://i.pravatar.cc/150?img=3",
            storyCount: widget.mediaPaths.length,
            currentIndex: currentIndex,
            progress: _animationController.value, // 👈 ADD THIS
            onClose: () {
              Navigator.pop(context);
            },
          ),

          /// BOTTOM BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(top: false, child: const StoryViewBottom()),
          ),
        ],
      ),
    );
  }
}
