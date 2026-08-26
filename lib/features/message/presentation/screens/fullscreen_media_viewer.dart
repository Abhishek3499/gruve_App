import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class FullscreenMediaViewer extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;

  const FullscreenMediaViewer({
    super.key,
    required this.mediaPath,
    required this.isVideo,
  });

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initVideo();
    }
  }

  void _initVideo() async {
    final path = widget.mediaPath.trim();
    final isLocal = !path.startsWith('http://') && !path.startsWith('https://');

    try {
      if (isLocal) {
        _videoController = VideoPlayerController.file(File(path));
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(path));
      }

      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      AppLogger.d('💥 [FullscreenMediaViewer] Video initialization failed: $e');
    }
  }

  void _togglePlay() {
    if (_videoController == null || !_isInitialized) return;
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
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
      body: Stack(
        children: [
          // Media content
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.isVideo ? _togglePlay : null,
              child: Center(
                child: widget.isVideo ? _buildVideo() : _buildImage(),
              ),
            ),
          ),

          // Play/Pause Overlay for video
          if (widget.isVideo && _isInitialized && !_isPlaying)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),

          // Close button top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final path = widget.mediaPath.trim();
    final isLocal = !path.startsWith('http://') && !path.startsWith('https://');

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      clipBehavior: Clip.none,
      child: isLocal
          ? Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
            )
          : CachedNetworkImage(
              imageUrl: path,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(
                color: Colors.white54,
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
            ),
    );
  }

  Widget _buildVideo() {
    if (_videoController == null || !_isInitialized) {
      return const CircularProgressIndicator(
        color: Colors.white54,
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }
}
