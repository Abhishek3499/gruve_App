import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/post/post_preview_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/screens/story_preview_screen.dart';
import '../utils/camera_logger.dart';

/// Simple text mode selector (Story / Gruve)
class ModeSelector extends StatefulWidget {
  const ModeSelector({super.key});

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector> {
  static const List<String> _modes = ['Story', 'Gruve'];
  final ImagePicker _imagePicker = ImagePicker();

  int _selectedModeIndex = 0;

  Future<void> openGallery() async {
    try {
      CameraLogger.logUserAction('Gallery opened');

      // Open gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        debugPrint('Selected gallery file path: ${pickedFile.path}');

        if (!mounted) return;
        if (_selectedModeIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StoryPreviewScreen(mediaPath: pickedFile.path),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PostPreviewScreen(mediaPath: pickedFile.path),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
  }

  void _onModeSelected(int index) {
    final mode = _modes[index];

    CameraLogger.logUserAction('Mode selector: $mode selected');

    setState(() {
      _selectedModeIndex = index;
    });
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
