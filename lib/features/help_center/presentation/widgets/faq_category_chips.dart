import 'package:flutter/material.dart';

class FaqCategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const FaqCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _CategoryChip(
            title: 'General',
            isSelected: selectedCategory == 'General',
            onTap: () => onCategoryChanged('General'),
          ),
          const SizedBox(width: 12),
          _CategoryChip(
            title: 'Account',
            isSelected: selectedCategory == 'Account',
            onTap: () => onCategoryChanged('Account'),
          ),
          const SizedBox(width: 12),
          _CategoryChip(
            title: 'Service',
            isSelected: selectedCategory == 'Service',
            onTap: () => onCategoryChanged('Service'),
          ),
          const SizedBox(width: 12),
          _CategoryChip(
            title: 'Other',
            isSelected: selectedCategory == 'Other',
            onTap: () => onCategoryChanged('Other'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF72008D) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
