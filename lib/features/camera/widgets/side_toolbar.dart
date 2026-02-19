import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controller/camera_controller_service.dart';
import '../utils/camera_logger.dart';

/// Dumb UI widget for side toolbar with various camera controls
/// Only handles UI rendering and user interaction callbacks
class SideToolbar extends StatelessWidget {
  SideToolbar({super.key});

  final CameraControllerService _cameraService = CameraControllerService();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFlashButton(),
        const SizedBox(height: 16),
        _buildMusicButton(),
        const SizedBox(height: 16),
        _buildTimerButton(),
        const SizedBox(height: 16),
        _buildEffectsButton(),
      ],
    );
  }

  Widget _buildFlashButton() {
    return StreamBuilder<bool>(
      stream: _cameraService.initializationStream,
      initialData: false,
      builder: (context, snapshot) {
        final isInitialized = snapshot.data ?? false;

        if (!isInitialized) {
          return _buildDisabledButton(Icons.flash_off);
        }

        return StreamBuilder<FlashMode>(
          stream: Stream.value(_cameraService.currentFlashMode),
          initialData: FlashMode.off,
          builder: (context, flashSnapshot) {
            final flashMode = flashSnapshot.data ?? FlashMode.off;
            final isFlashOn = flashMode != FlashMode.off;

            return GestureDetector(
              onTap: () {
                CameraLogger.logUserAction('Flash button pressed');
                _cameraService.toggleFlash();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFlashOn
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMusicButton() {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Music button pressed');
        _showComingSoon('Music');
      },
      child: _buildEnabledButton(Icons.music_note),
    );
  }

  Widget _buildTimerButton() {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Timer button pressed');
        _showComingSoon('Timer');
      },
      child: _buildEnabledButton(Icons.timer),
    );
  }

  Widget _buildEffectsButton() {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Effects button pressed');
        _showComingSoon('Effects');
      },
      child: _buildEnabledButton(Icons.auto_fix_high),
    );
  }

  Widget _buildEnabledButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildDisabledButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
    );
  }

  void _showComingSoon(String feature) {
    // This would show a toast or snackbar
    // For now, just log the action
    CameraLogger.logUserAction('$feature feature requested (coming soon)');
  }
}
