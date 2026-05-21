import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final String videoPath;
  final Widget child;
  final double overlayOpacity;

  const VideoBackground({
    super.key,
    required this.videoPath,
    required this.child,
    this.overlayOpacity = 0.45,
  });

  @override
  State<VideoBackground> createState() => VideoBackgroundState();
}

class VideoBackgroundState extends State<VideoBackground>
    with WidgetsBindingObserver {
  static VideoPlayerController? _sharedController;
  static bool _isInitializing = false;
  static int _instanceCount = 0;
  static final ValueNotifier<int> _controllerVersion = ValueNotifier<int>(0);

  // Expose the shared controller for external access
  static VideoPlayerController? get sharedController => _sharedController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controllerVersion.addListener(_onSharedControllerChanged);
    _instanceCount++;
    _initializeSharedController();
  }

  Future<void> _initializeSharedController() async {
    if (_sharedController != null || _isInitializing) return;

    _isInitializing = true;
    try {
      _sharedController = VideoPlayerController.asset(widget.videoPath);
      await _sharedController!.initialize();
      await _sharedController!.setLooping(true);
      await _sharedController!.setVolume(0);
      await _sharedController!.play();
    } catch (e) {
      _sharedController?.dispose();
      _sharedController = null;
    } finally {
      _isInitializing = false;
      _controllerVersion.value++;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controllerVersion.removeListener(_onSharedControllerChanged);
    _instanceCount--;
    if (_instanceCount == 0 && _sharedController != null) {
      _sharedController!.dispose();
      _sharedController = null;
      _controllerVersion.value++;
    }
    super.dispose();
  }

  void _onSharedControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _sharedController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      controller.pause();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // VIDEO
        RepaintBoundary(
          child:
              _sharedController != null &&
                  _sharedController!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _sharedController!.value.size.width,
                    height: _sharedController!.value.size.height,
                    child: VideoPlayer(_sharedController!),
                  ),
                )
              : const ColoredBox(
                  color: Colors.black,
                  child: SizedBox.expand(),
                ),
        ),

        // OVERLAY (only if opacity > 0)
        if (widget.overlayOpacity > 0)
          Container(
            color: Colors.black.withAlpha(
              (widget.overlayOpacity.clamp(0.0, 1.0) * 255).round(),
            ),
          ),

        // CHILD UI (always on top)
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
