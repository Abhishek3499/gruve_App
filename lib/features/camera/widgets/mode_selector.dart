import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../utils/camera_logger.dart';

/// Simple text mode selector (Story / Gruve)
class ModeSelector extends StatefulWidget {
  const ModeSelector({super.key});

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector> {
  static const List<String> _modes = ['Story', 'Gruve'];

  int _selectedModeIndex = 0;

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
            onPressed: () {
              CameraLogger.logUserAction('Gallery opened');
            },
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
