import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gruve_app/core/assets.dart';
import '../controller/camera_controller_service.dart';
import '../utils/camera_logger.dart';
import 'emoji_picker_sheet.dart';

class SideToolbar extends StatelessWidget {
  final Function(String)? onEmojiSelected;
  final VoidCallback? onMusicTap;
  final VoidCallback? onTimerTap;

  SideToolbar({
    super.key,
    this.onEmojiSelected,
    this.onMusicTap,
    this.onTimerTap,
  });

  final CameraControllerService _cameraService = CameraControllerService();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 35),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMusicButton(),
          const SizedBox(height: 28),
          _buildTimerButton(),
          const SizedBox(height: 28),
          _buildFlashButton(),

          const SizedBox(height: 28),
          _buildEffectsButton(),
          const SizedBox(height: 28),
          _buildemojiButton(),
        ],
      ),
    );
  }

  /// FLASH BUTTON (logic same, UI cleaned)
  Widget _buildFlashButton() {
    return StreamBuilder<bool>(
      stream: _cameraService.initializationStream,
      initialData: false,
      builder: (context, snapshot) {
        final isInitialized = snapshot.data ?? false;

        if (!isInitialized) {
          return _buildDisabledIcon(Icons.flash_off);
        }

        return StreamBuilder<FlashMode>(
          stream: _cameraService.flashModeStream,
          initialData: FlashMode.off,
          builder: (context, flashSnapshot) {
            final flashMode = flashSnapshot.data ?? FlashMode.off;
            final isFlashOn = flashMode != FlashMode.off;

            return GestureDetector(
              onTap: () {
                CameraLogger.logUserAction('Flash button pressed');
                _cameraService.toggleFlash();
              },
              child: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 28,
              ),
            );
          },
        );
      },
    );
  }

  /// MUSIC BUTTON
  Widget _buildMusicButton() {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Music button pressed');
        if (onMusicTap != null) {
          onMusicTap!();
        } else {
          _showComingSoon('Music');
        }
      },
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  /// TIMER BUTTON
  Widget _buildTimerButton() {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Timer button pressed');
        if (onTimerTap != null) {
          onTimerTap!();
        } else {
          _showComingSoon('Timer');
        }
      },
      child: const Icon(Icons.timer, color: Colors.white, size: 28),
    );
  }

  /// EFFECT BUTTON
  Widget _buildEffectsButton() {
    return GestureDetector(
      onTap: () {
        CameraLogger.logUserAction('Effects button pressed');
        _showComingSoon('Effects');
      },
      child: Image.asset(
        AppAssets.tymer,
        color: Colors.white,
        height: 26,
        width: 26,
      ),
    );
  }

  Widget _buildemojiButton() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () async {
            CameraLogger.logUserAction('Emoji button pressed');
            final emoji = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const EmojiPickerSheet(),
            );
            if (emoji != null && onEmojiSelected != null) {
              onEmojiSelected!(emoji);
            }
          },
          child: Image.asset(AppAssets.emoji, width: 28, height: 28),
        );
      }
    );
  }

  /// DISABLED ICON
  Widget _buildDisabledIcon(IconData icon) {
    return Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 28);
  }

  void _showComingSoon(String feature) {
    CameraLogger.logUserAction('$feature feature requested (coming soon)');
  }
}
