import 'package:flutter/material.dart';
import '../controller/camera_controller_service.dart';
import '../utils/camera_logger.dart';

/// Dumb UI widget for capture button
/// Only handles UI rendering and user interaction callbacks
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
    _initializeAnimation();
    _initializeListeners();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeListeners() {
    _cameraService.captureStream.listen((isCapturing) {
      if (mounted) {
        setState(() {
          _isCapturing = isCapturing;
        });
        
        if (isCapturing) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  Future<void> _onCapturePressed() async {
    if (_isCapturing) return;

    CameraLogger.logUserAction('Capture button pressed');
    
    // Add haptic feedback
    _triggerHapticFeedback();
    
    // Capture image through service
    await _cameraService.captureImage();
  }

  void _triggerHapticFeedback() {
    // Light haptic feedback for button press
    // Note: You can add haptic feedback package if needed
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
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                color: _isCapturing 
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _buildButtonContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    if (_isCapturing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    CameraLogger.logVerbose('CaptureButton disposed');
    super.dispose();
  }
}
