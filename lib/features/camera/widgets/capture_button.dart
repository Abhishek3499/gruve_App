import 'dart:async';
import 'package:flutter/material.dart';
import '../controller/camera_controller_service.dart';
import '../services/mode_service.dart';
import '../utils/camera_logger.dart';

class CaptureButton extends StatefulWidget {
  const CaptureButton({super.key});

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton>
    with SingleTickerProviderStateMixin {
  final CameraControllerService _cameraService = CameraControllerService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isCapturing = false;
  bool _isRecordingVideo = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  double _dragStartY = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initListeners();
    _initZoomLevels();
  }

  Future<void> _initZoomLevels() async {
    final controller = _cameraService.controller;
    if (controller != null && controller.value.isInitialized) {
      _maxZoom = _cameraService.maxZoom;
      _minZoom = _cameraService.minZoom;
      _currentZoom = _cameraService.currentZoom;
    }
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initListeners() {
    _cameraService.captureStream.listen((isCapturing) {
      if (!mounted) return;

      setState(() {
        _isCapturing = isCapturing;
      });

      if (isCapturing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    _cameraService.videoRecordingStream.listen((isRecording) {
      if (!mounted) return;

      setState(() {
        _isRecordingVideo = isRecording;
      });

      if (isRecording) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturing) return;

    if (_isRecordingVideo) {
      await _stopRecordingAndNavigate();
      return;
    }

    CameraLogger.logUserAction('Image capture started (tap)');

    final image = await _cameraService.captureImage();

    if (image != null && mounted) {
      final mode = ModeService().selectedMode;
      Navigator.of(context).pop(
        CameraCaptureResult(
          mediaPath: image.path,
          mode: mode,
          stickers: List.from(ModeService().stickers),
        ),
      );
    }
  }

  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    if (_isCapturing || _isRecordingVideo) return;

    CameraLogger.logUserAction('Video recording started (long press)');

    // Store initial position and zoom
    _dragStartY = details.globalPosition.dy;
    _baseZoom = _currentZoom;

    // Start video recording
    await _cameraService.startVideoRecording();

    // Start timer
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  Future<void> _onLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
  ) async {
    if (!_isRecordingVideo) return;

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;

    // Calculate zoom based on vertical drag
    // Swipe up (negative delta) = zoom in
    // Swipe down (positive delta) = zoom out
    final dragDelta = _dragStartY - details.globalPosition.dy;
    final zoomSensitivity = 0.005; // Adjust sensitivity

    double newZoom = _baseZoom + (dragDelta * zoomSensitivity);
    newZoom = newZoom.clamp(_minZoom, _maxZoom);

    if ((newZoom - _currentZoom).abs() > 0.01) {
      _currentZoom = newZoom;
      await _cameraService.setZoomLevel(_currentZoom);
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _stopRecordingAndNavigate() async {
    if (!_isRecordingVideo) return;

    CameraLogger.logUserAction('Video recording stopped');

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final controller = _cameraService.controller;
    if (controller != null && controller.value.isInitialized) {
      await _cameraService.setZoomLevel(_minZoom);
      _currentZoom = _minZoom;
      _baseZoom = _minZoom;
    }

    final video = await _cameraService.stopVideoRecording();

    if (video != null && mounted) {
      final mode = ModeService().selectedMode;
      Navigator.of(context).pop(
        CameraCaptureResult(
          mediaPath: video.path,
          mode: mode,
          stickers: List.from(ModeService().stickers),
        ),
      );
    }
  }

  Future<void> _onLongPressEnd(LongPressEndDetails details) async {
    await _stopRecordingAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _onCapturePressed,
            onLongPressStart: _onLongPressStart,
            onLongPressMoveUpdate: _onLongPressMoveUpdate,
            onLongPressEnd: _onLongPressEnd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Outer Ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecordingVideo ? Colors.red : Colors.white,
                      width: 3,
                    ),
                  ),
                ),

                /// Inner Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecordingVideo ? Colors.red : Colors.white,
                  ),
                ),

                /// Loading indicator
                if (_isCapturing || _isRecordingVideo)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 3,
                    ),
                  ),

                /// Recording indicator with timer and zoom
                if (_isRecordingVideo)
                  Positioned(
                    top: -35,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatDuration(_recordingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_currentZoom > _minZoom + 0.1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_currentZoom.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                /// Zoom hint on first long press
                if (_isRecordingVideo && _recordingSeconds < 2)
                  Positioned(
                    bottom: -40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Swipe up to zoom',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _animationController.dispose();
    CameraLogger.logVerbose('CaptureButton disposed');
    super.dispose();
  }
}
