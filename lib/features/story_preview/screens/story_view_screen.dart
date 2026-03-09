import 'dart:io';
import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_view_bottom.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_viewer_topbar.dart';
// 👈 tumhara bottom widget

class StoryViewScreen extends StatefulWidget {
  final String mediaPath;

  const StoryViewScreen({super.key, required this.mediaPath});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();

    _isVideo =
        widget.mediaPath.toLowerCase().endsWith(".mp4") ||
        widget.mediaPath.toLowerCase().endsWith(".mov") ||
        widget.mediaPath.toLowerCase().endsWith(".avi");

    if (_isVideo) {
      _videoController = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
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

    return Image.file(File(widget.mediaPath), fit: BoxFit.cover);
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
            username: "abhi_sharma",
            time: "4h",
            avatarUrl: "https://i.pravatar.cc/150?img=3",
            storyCount: 5,
            currentIndex: 1,
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
