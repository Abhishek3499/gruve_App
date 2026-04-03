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
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initListeners();
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
    if (_isCapturing || _isRecordingVideo) return;

    CameraLogger.logUserAction('Capture button pressed (short press)');

    final image = await _cameraService.captureImage();

    if (image != null && mounted) {
      final mode = ModeService().selectedMode;
      // Route intent must match ModeSelector: story → StoryPreview, groove → PostPreview (via CameraHandler).
      if (mode == CameraMode.story) {
        Navigator.of(context).pop(
          CameraCaptureResult(mediaPath: image.path, mode: CameraMode.story),
        );
      } else if (mode == CameraMode.groove) {
        Navigator.of(context).pop(
          CameraCaptureResult(mediaPath: image.path, mode: CameraMode.groove),
        );
      }
    }
  }

  Future<void> _onLongPressStart() async {
    if (_isCapturing || _isRecordingVideo) return;

    setState(() {
      _isLongPressing = true;
    });

    CameraLogger.logUserAction('Video recording started (long press)');

    // Start video recording
    await _cameraService.startVideoRecording();
  }

  Future<void> _onLongPressEnd() async {
    if (!_isRecordingVideo) return;

    setState(() {
      _isLongPressing = false;
    });

    CameraLogger.logUserAction('Video recording stopped (long press released)');

    // Stop video recording and get the video file
    final video = await _cameraService.stopVideoRecording();

    if (video != null && mounted) {
      final mode = ModeService().selectedMode;
      if (mode == CameraMode.story) {
        Navigator.of(context).pop(
          CameraCaptureResult(mediaPath: video.path, mode: CameraMode.story),
        );
      } else if (mode == CameraMode.groove) {
        Navigator.of(context).pop(
          CameraCaptureResult(mediaPath: video.path, mode: CameraMode.groove),
        );
      }
    }
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
            onLongPressStart: (_) => _onLongPressStart(),
            onLongPressEnd: (_) => _onLongPressEnd(),
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

                /// Recording indicator
                if (_isRecordingVideo)
                  Positioned(
                    top: -25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  void dispose() {
    _animationController.dispose();
    CameraLogger.logVerbose('CaptureButton disposed');
    super.dispose();
  }
}
