import 'package:flutter/material.dart';
import '../utils/camera_logger.dart';

/// Dumb UI widget for mode selector (Story/Gruve style toggle)
/// Only handles UI rendering and user interaction callbacks
class ModeSelector extends StatefulWidget {
  const ModeSelector({super.key});

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector> {
  static const List<String> _modes = ['Story', 'Gruve'];
  int _selectedModeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: List.generate(
          _modes.length,
          (index) => _buildModeItem(index),
        ),
      ),
    );
  }

  Widget _buildModeItem(int index) {
    final isSelected = index == _selectedModeIndex;
    final mode = _modes[index];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          CameraLogger.logUserAction('Mode selector: $mode selected');
          setState(() {
            _selectedModeIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              mode,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
