import 'package:flutter/material.dart';
import 'package:gruve_app/shared/widgets/reels_icon.dart';

class FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const FilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  Widget _buildTab({
    IconData? icon,
    Widget? customIcon,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          customIcon ??
              Icon(
                icon!,
                size: 22,
                color: isSelected ? Colors.white : Colors.white54,
              ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 36 : 0,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFE024C3), Color(0xFF8B5CF6)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: _buildTab(
                customIcon: ReelsIcon(
                  size: 21,
                  color: selectedIndex == 0 ? Colors.white : Colors.white54,
                ),
                index: 0,
              ),
            ),
            Expanded(
              child: _buildTab(
                icon: Icons.grid_view_rounded,
                index: 1,
              ),
            ),
            Expanded(
              child: _buildTab(
                icon: Icons.portrait_rounded,
                index: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
