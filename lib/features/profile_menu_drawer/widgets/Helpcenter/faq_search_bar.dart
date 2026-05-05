import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';

class FaqSearchBar extends StatelessWidget {
  final String selectedCategory;

  const FaqSearchBar({super.key, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomSearchBar(
        hintText: selectedCategory == 'General' ? 'Why I' : '',
        height: 65,
        backgroundColor: const Color(0xFF4A1F5C).withValues(alpha: 0.3),
        borderGradient: null,
        border: Border.all(color: const Color(0xFF7E92F8), width: 1),
        borderWidth: 0,
        borderRadius: 25,
        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 30),
        hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }
}
