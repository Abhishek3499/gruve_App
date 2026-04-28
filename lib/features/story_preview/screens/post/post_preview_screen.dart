import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/post/share_post_screen.dart';

import 'package:gruve_app/features/story_preview/api/post/post_action_buttons.dart';

import 'package:video_player/video_player.dart';

class PostPreviewScreen extends StatefulWidget {
  final String mediaPath;

  const PostPreviewScreen({super.key, required this.mediaPath});

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  void _initializeMedia() async {
    final file = File(widget.mediaPath);

    _isVideo =
        widget.mediaPath.toLowerCase().endsWith('.mp4') ||
        widget.mediaPath.toLowerCase().endsWith('.mov') ||
        widget.mediaPath.toLowerCase().endsWith('.avi');

    if (_isVideo) {
      _videoController = VideoPlayerController.file(file);

      await _videoController!.initialize();

      _videoController!
        ..setLooping(true)
        ..play();

      setState(() {
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// MEDIA PREVIEW
            Expanded(
              child: Stack(
                children: [
                  /// MEDIA
                  Positioned.fill(
                    child: _isInitialized
                        ? _buildMediaPreview()
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),

                  /// TOP BAR + ACTION BUTTONS (ONE ROW)
                  Positioned(
                    bottom: 28, // 👈 important
                    left: 0,
                    right: 0,
                    child: Center(child: PostActionButtons()),
                  ),
                ],
              ),
            ),

            /// BOTTOM ACTION SECTION
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// EDIT VIDEO (LEFT)
                        SizedBox(
                          width: 120, // 👈 control size
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const ui.Color.fromARGB(155, 120, 2, 99),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "Edit Video",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        /// NEXT (RIGHT)
                        GestureDetector(
                          onTap: () {
                            try {
                              debugPrint(
                                'PostPreviewScreen navigating with mediaPath: ${widget.mediaPath}',
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SharePostScreen(
                                    mediaPath: widget.mediaPath,
                                    popPostPreviewRouteAfterShare: true,
                                  ),
                                ),
                              );
                            } catch (e) {
                              debugPrint('Navigation error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error navigating: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          child: SizedBox(
                            width: 100, // 👈 thoda chhota
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: const ui.Color.fromARGB(155, 120, 2, 99),
                              ),
                              alignment: Alignment.center,
                              child: const Text("Next"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_isVideo && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return Image.file(
      File(widget.mediaPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        );
      },
    );
  }
}
