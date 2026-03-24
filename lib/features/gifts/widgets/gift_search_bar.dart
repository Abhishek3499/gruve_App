import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

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
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromARGB(26, 57, 6, 79),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Color.fromARGB(51, 240, 58, 250), width: 2),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search Gift',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
          suffixIcon: IconButton(
            icon: Image.asset(AppAssets.forward, height: 22, width: 22),
            onPressed: onSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
