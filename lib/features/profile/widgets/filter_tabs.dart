import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const FilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  Widget buildTab(String text, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFF7D63D1), const Color(0xFF212235)]
                : [
                    const Color(0xFF7D63D1).withValues(alpha: 0.3),
                    const Color(0xFF212235).withValues(alpha: 0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildTab("All", 0),
        buildTab("Trending", 1),
        buildTab("Likes", 2),
      ],
    );
  }
}
