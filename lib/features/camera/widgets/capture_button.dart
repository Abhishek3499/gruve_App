import 'package:flutter/material.dart';
import '../controller/camera_controller_service.dart';
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
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturing) return;

    CameraLogger.logUserAction('Capture button pressed');

    final image = await _cameraService.captureImage();

    if (image != null && mounted) {
      Navigator.of(context).pop(image.path);
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Outer Ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),

                /// Inner Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),

                /// Loading indicator
                if (_isCapturing)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 3,
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
