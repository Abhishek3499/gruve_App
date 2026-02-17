import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onTap,
    this.onChanged,
    this.hintText = "Search Users, Hashtags",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2), // 👈 for gradient border
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD42BC2), // Pink
            Color(0xFF6BA9F6), // Blue
          ],
        ),
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF7A1FA2), // Inner purple
        ),
        child: TextField(
          controller: controller,
          onTap: onTap,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
            hintText: "Search Users, Hashtags",
            hintStyle: TextStyle(color: Colors.white70),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
