import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VideoEditorScreen extends StatefulWidget {
  final String mediaPath;

  const VideoEditorScreen({super.key, required this.mediaPath});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;

  // Trim adjustments (mock values between 0.0 and 1.0 for handles)
  double _startTrim = 0.1;
  double _endTrim = 0.9;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  void _initializeMedia() async {
    final file = File(widget.mediaPath);
    _isVideo = widget.mediaPath.toLowerCase().endsWith('.mp4') ||
        widget.mediaPath.toLowerCase().endsWith('.mov') ||
        widget.mediaPath.toLowerCase().endsWith('.avi');

    if (_isVideo) {
      _videoController = VideoPlayerController.file(file);
      try {
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _currentPosition = _videoController!.value.position;
              _isPlaying = _videoController!.value.isPlaying;
            });
          }
        });
        setState(() {
          _duration = _videoController!.value.duration;
          _isInitialized = true;
        });
        _videoController!.play();
      } catch (e) {
        AppLogger.d('Error initializing video editor: $e');
      }
    } else {
      setState(() {
        _isInitialized = true;
        _duration = const Duration(seconds: 1);
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    if (_isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = _duration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF33093C),
              Color(0xFF1B071F),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. TOP HEADER (Chevrons)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Next / Forward button in white circle
                    GestureDetector(
                      onTap: () {
                        // Return the edited results or simply pop back
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF6B1D7C),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. VIDEO PREVIEW (Center section)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isInitialized)
                                _isVideo
                                    ? SizedBox.expand(
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: _videoController!.value.size.width,
                                            height: _videoController!.value.size.height,
                                            child: VideoPlayer(_videoController!),
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        File(widget.mediaPath),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                              else
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. PLAY/PAUSE CONTROLS & TIMESTAMPS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: SizedBox(
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Play/Pause button on the left
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      // Duration Text centered
                      Text(
                        '${_formatDuration(_currentPosition)} / ${_formatDuration(_duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // // Horizontal divider
              // Divider(
              //   color: Colors.white.withValues(alpha: 0.15),
              //   height: 1,
              //   thickness: 1,
              // ),

              // 4. TIMELINE SECTION (Middle section)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final timelineWidth = constraints.maxWidth;
                      final cursorOffset = timelineWidth * progressFraction;

                      return Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Timestamp markers (• 1s •) aligned with trim bounds
                              SizedBox(
                                width: timelineWidth,
                                height: 20,
                                child: Stack(
                                  children: [
                                    // Left dot aligned with left handle
                                    Positioned(
                                      left: timelineWidth * _startTrim - 2,
                                      top: 8,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    // Centered duration text between handles
                                    Positioned(
                                      left: timelineWidth * _startTrim,
                                      right: timelineWidth * (1 - _endTrim),
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Text(
                                          '${_duration.inSeconds > 0 ? _duration.inSeconds : 1}s',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Right dot aligned with right handle
                                    Positioned(
                                      left: timelineWidth * _endTrim - 2,
                                      top: 8,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Timeline video track & trim handles
                              SizedBox(
                                height: 50,
                                child: Stack(
                                  children: [
                                    // Main strip representing video
                                    Positioned(
                                      left: timelineWidth * _startTrim,
                                      right: timelineWidth * (1 - _endTrim),
                                      top: 4,
                                      bottom: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                          image: const DecorationImage(
                                            image: AssetImage(AppAssets.img2),
                                            fit: BoxFit.cover,
                                            colorFilter: ColorFilter.mode(
                                              Colors.black26,
                                              BlendMode.darken,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Trim handles
                                    // Left Handle
                                    Positioned(
                                      left: timelineWidth * _startTrim - 6,
                                      top: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onHorizontalDragUpdate: (details) {
                                          setState(() {
                                            double delta = details.primaryDelta! / timelineWidth;
                                            _startTrim = (_startTrim + delta).clamp(0.0, _endTrim - 0.1);
                                          });
                                        },
                                        child: Container(
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          alignment: Alignment.center,
                                          child: Container(
                                            width: 1.5,
                                            height: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Right Handle
                                    Positioned(
                                      left: timelineWidth * _endTrim - 6,
                                      top: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onHorizontalDragUpdate: (details) {
                                          setState(() {
                                            double delta = details.primaryDelta! / timelineWidth;
                                            _endTrim = (_endTrim + delta).clamp(_startTrim + 0.1, 1.0);
                                          });
                                        },
                                        child: Container(
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          alignment: Alignment.center,
                                          child: Container(
                                            width: 1.5,
                                            height: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tap tp add music & text horizontal cards
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionPill(
                                    leading: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: 'Tap tp add music',
                                    onTap: () {
                                      AppLogger.d('Timeline: Add Music tapped');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionPill(
                                    leading: const Text(
                                      'Aa',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    label: 'Tap tp add text',
                                    onTap: () {
                                      AppLogger.d('Timeline: Add Text tapped');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Vertical cursor line
                          Positioned(
                            left: cursorOffset.clamp(0.0, timelineWidth - 2.0),
                            top: 25,
                            bottom: 10,
                            child: Container(
                              width: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // 5. BOTTOM ACTION TOOLBAR
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
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildBottomIconButton(
                                const Icon(Icons.volume_up, color: Colors.white, size: 24),
                                'Volume',
                              ),
                              _buildBottomIconButton(
                                Image.asset(AppAssets.text, color: Colors.white, width: 22, height: 22),
                                'Text',
                              ),
                              _buildBottomIconButton(
                                Image.asset(AppAssets.musics, color: Colors.white, width: 22, height: 22),
                                'Music',
                              ),
                              _buildBottomIconButton(
                                Image.asset(AppAssets.filter, color: Colors.white, width: 22, height: 22),
                                'Filter',
                              ),
                              _buildBottomIconButton(
                                Image.asset(AppAssets.cuts, color: Colors.white, width: 22, height: 22),
                                'Trim',
                              ),
                              _buildBottomIconButton(
                                Image.asset(AppAssets.download2, color: Colors.white, width: 22, height: 22),
                                'Download',
                              ),
                              _buildBottomIconButton(
                                Image.asset(AppAssets.gallery2, color: Colors.white, width: 22, height: 22),
                                'Gallery',
                              ),
                            ],
                          ),
                        ),
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
  }

  Widget _buildActionPill({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF481358), // Exact dark purple matching screenshot
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIconButton(Widget icon, String tooltip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}
