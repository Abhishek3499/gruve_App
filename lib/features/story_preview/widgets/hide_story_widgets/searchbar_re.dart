import 'package:flutter/material.dart';

class SearchbarRe extends StatelessWidget {
  final String hintText; // 👈 add this

  const SearchbarRe({super.key, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 362,
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
          ),
        ),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF72008D), Color(0xFF511263)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: TextField(
            style: const TextStyle(color: Colors.white),

            decoration: InputDecoration(
              border: InputBorder.none,
              icon: const Icon(Icons.search, color: Colors.white70, size: 20),

              hintText: hintText, // 🔥 dynamic text
              hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
