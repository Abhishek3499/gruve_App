import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import 'package:gruve_app/features/story_preview/widgets/story_action_buttons.dart';
import 'package:gruve_app/features/story_preview/widgets/story_top_bar.dart';
import 'package:gruve_app/widgets/story_share_sheet.dart';
import 'package:video_player/video_player.dart';

class StoryPreviewScreen extends StatefulWidget {
  final String mediaPath;

  const StoryPreviewScreen({super.key, required this.mediaPath});

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
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
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        StoryTopBar(onClose: () => Navigator.pop(context)),
                        StoryActionButtons(),
                      ],
                    ),
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
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                    child: Row(
                      children: [
                        /// YOUR STORY
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ), // 🔥 add this
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color(0xFF72008D),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(AppAssets.profile),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 6,
                                ), // 🔥 spacing same karo
                                const Text(
                                  "Your Story",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// CLOSE FRIEND
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Color(0xFF72008D),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 25,
                                height: 25,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Close Friend",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 15),

                        /// SEND
                        GestureDetector(
                          onTap: () {
                            // Navigator.push ki jagah ye use karein:
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled:
                                  true, // Zaroori hai taaki size content ke hisaab se ho
                              backgroundColor: Colors
                                  .transparent, // Takki rounded corners dikhein
                              builder: (context) => const StoryShareSheet(),
                            );
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF9544A7),
                              size: 15,
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
