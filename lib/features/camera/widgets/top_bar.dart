import 'package:flutter/material.dart';
import '../controller/camera_controller_service.dart';
import '../utils/camera_logger.dart';

/// Dumb UI widget for top bar with close and flip camera buttons
/// Only handles UI rendering and user interaction callbacks
class TopBar extends StatelessWidget {
  TopBar({super.key});

  final CameraControllerService _cameraService = CameraControllerService();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildCloseButton(context), _buildFlipCameraButton()],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Close button pressed');
        Navigator.of(context).pop();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFlipCameraButton() {
    return StreamBuilder<bool>(
      stream: _cameraService.initializationStream,
      initialData: false,
      builder: (context, snapshot) {
        final isInitialized = snapshot.data ?? false;
        final hasMultipleCameras = _cameraService.cameras.length > 1;

        if (!isInitialized || !hasMultipleCameras) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            CameraLogger.logUserAction('Flip camera button pressed');
            _cameraService.switchCamera();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
