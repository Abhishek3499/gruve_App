import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';

class GiftSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const GiftSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomSearchBar(
        controller: controller,
        hintText: 'Search Gift',
        backgroundColor: const Color.fromARGB(26, 57, 6, 79),
        borderGradient: null,
        border: Border.all(
          color: const Color.fromARGB(51, 240, 58, 250),
          width: 2,
        ),
        borderWidth: 0,
        borderRadius: 25,
        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
        suffixIcon: IconButton(
          icon: Image.asset(AppAssets.forward, height: 22, width: 22),
          onPressed: onSearch,
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }
}
