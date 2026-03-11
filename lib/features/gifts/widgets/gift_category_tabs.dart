import 'package:flutter/material.dart';

enum GiftCategory { new_, general, love }

class GiftCategoryTabs extends StatelessWidget {
  final GiftCategory selectedCategory;
  final Function(GiftCategory) onCategorySelected;

  const GiftCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // NEW tab
          _buildTab(
            title: 'NEW',
            isActive: selectedCategory == GiftCategory.new_,
            onTap: () => onCategorySelected(GiftCategory.new_),
          ),

          const SizedBox(width: 20),

          // GENERAL tab
          _buildTab(
            title: 'GENERAL',
            isActive: selectedCategory == GiftCategory.general,
            onTap: () => onCategorySelected(GiftCategory.general),
          ),

          const SizedBox(width: 20),

          // LOVE tab
          _buildTab(
            title: 'LOVE',

            isActive: selectedCategory == GiftCategory.love,
            onTap: () => onCategorySelected(GiftCategory.love),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFCD72E3) : Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
