import 'package:flutter/material.dart';

class SearchbarRe extends StatelessWidget {
  const SearchbarRe({super.key});

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

        /// INNER BACKGROUND
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

          child: const TextField(
            style: TextStyle(color: Colors.white),

            decoration: InputDecoration(
              border: InputBorder.none,

              icon: Icon(Icons.search, color: Colors.white70, size: 20),

              hintText: "Search",
              hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
