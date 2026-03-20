import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/profile/widgets/draft_tile.dart';

class ReelsDraftsScreen extends StatelessWidget {
  const ReelsDraftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark Purple Gradient Background
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 73, 3, 87),
              Color.fromARGB(255, 14, 1, 16), // Near black bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Custom AppBar ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Image.asset(AppAssets.back, height: 24, width: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Reels Drafts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer for balance
                  ],
                ),
              ),

              // --- Draft List ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 1, // Change according to your data
                  itemBuilder: (context, index) {
                    return const DraftTile();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
