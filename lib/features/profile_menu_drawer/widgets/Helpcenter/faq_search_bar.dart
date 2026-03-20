import 'package:flutter/material.dart';

class FaqSearchBar extends StatelessWidget {
  final String selectedCategory;

  const FaqSearchBar({super.key, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF4A1F5C).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF7E92F8), width: 1),
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 30),
          hintText: selectedCategory == 'General' ? 'Why I' : null,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
