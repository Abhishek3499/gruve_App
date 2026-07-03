import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/screens/post/post_preview_navigation.dart';
import 'package:gruve_app/features/story_preview/screens/post/post_preview_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/share_post_sheet.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/screens/story_preview_screen.dart';
import 'package:gruve_app/features/ideas/screen/ideas_screen.dart';
import 'package:provider/provider.dart';
import '../utils/camera_logger.dart';
import '../services/mode_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';

/// Simple text mode selector (Story / Gruve)
class ModeSelector extends StatefulWidget {
  const ModeSelector({super.key});

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector> {
  static const List<String> _modes = ['Story', 'Gruve'];
  final ImagePicker _imagePicker = ImagePicker();
  final ModeService _modeService = ModeService();

  late int _selectedModeIndex;

  @override
  void initState() {
    super.initState();
    _selectedModeIndex = _modeService.selectedMode == CameraMode.story ? 0 : 1;
    // Keep singleton in sync with the visible tab when camera opens (capture reads ModeService).
    if (_selectedModeIndex == 0) {
      _modeService.setStoryMode();
    } else {
      _modeService.setGrooveMode();
    }
  }

  Future<void> openGallery() async {
    try {
      CameraLogger.logUserAction('Gallery opened');

      // Story and Gruve can be either video or image — gallery shows both.
      final XFile? pickedFile = await _imagePicker.pickMedia(
        imageQuality: 85,
      );

      if (pickedFile != null) {
        AppLogger.d('Selected gallery file path: ${pickedFile.path}');

        final isVideo = LocalMediaUtils.isVideoPath(
          pickedFile.path,
          mimeType: pickedFile.mimeType,
        );
        final isImage = LocalMediaUtils.isImagePath(
          pickedFile.path,
          mimeType: pickedFile.mimeType,
        );

        if (!isVideo && !isImage) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image or video'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!mounted) return;
        if (_modeService.selectedMode == CameraMode.story) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => StoryController(),
                child: StoryPreviewScreen(
                  mediaPath: pickedFile.path,
                  mediaMimeType: pickedFile.mimeType,
                ),
              ),
            ),
          );
        } else if (_modeService.selectedMode == CameraMode.groove) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostPreviewScreen(
                mediaPath: pickedFile.path,
                mediaMimeType: pickedFile.mimeType,
              ),
            ),
          );
          if (!mounted) return;
          if (result is PostPreviewOpenShare) {
            Navigator.of(context).pop();
            await Future<void>.delayed(Duration.zero);
            if (!mounted) return;
            final shareResult = await showSharePostOnHomeSheet(
              result.mediaPath,
              mediaMimeType: result.mediaMimeType,
            );
            if (shareResult == 'start_processing') {
              // Detect media type from file path
              final isVideo = LocalMediaUtils.isVideoPath(
                result.mediaPath,
                mimeType: null,
              );
              PostShareFlowBridge.notifyShareStartProcessing(isVideo);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.d('Error picking from gallery: $e');
    }
  }

  void _onModeSelected(int index) {
    final mode = _modes[index];

    CameraLogger.logUserAction('Mode selector: $mode selected');

    setState(() {
      _selectedModeIndex = index;
    });

    // Update the global mode service
    if (index == 0) {
      _modeService.setStoryMode();
    } else {
      _modeService.setGrooveMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// LEFT ICON (Gallery)
          IconButton(
            onPressed: openGallery,
            icon: Image.asset(AppAssets.gallery, width: 32, height: 32),
          ),

          /// MODES (UNCHANGED LOGIC)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _modes.length,
              (index) => _buildModeItem(index),
            ),
          ),

          /// RIGHT ICON (Idea / Info)
          IconButton(
            onPressed: () {
              CameraLogger.logUserAction('Idea icon clicked');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IdeasScreen(),
                ),
              );
            },
            icon: Image.asset(AppAssets.idea, width: 32, height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem(int index) {
    final isSelected = index == _selectedModeIndex;
    final mode = _modes[index];

    return GestureDetector(
      onTap: () => _onModeSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 1,
          ),
          child: Text(mode.toUpperCase()),
        ),
      ),
    );
  }
}
