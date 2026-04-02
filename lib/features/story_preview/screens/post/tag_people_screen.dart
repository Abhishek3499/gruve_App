import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/message/screen/search_users_screen.dart';

class TagPeopleScreen extends StatelessWidget {
  final String mediaPath;

  const TagPeopleScreen({super.key, required this.mediaPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            colors: [Color(0xFF2A0944), Color(0xFF0D0214)],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// 1. CUSTOM HEADER (Back, Title, Done)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        AppAssets.back,
                        color: Colors.white,
                        height: 24,
                      ),
                    ),
                    const Text(
                      "Tag People",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          color: Color(0xFF007AFF), // iOS Blue color
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// 2. MAIN CONTENT
              SizedBox(height: 30),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // MEDIA PREVIEW CARD
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: _buildMediaPreview(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // TAP TO TAG BUTTON
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchUsersScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Tap to Tag People",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (mediaPath.startsWith('http')) {
      return Image.network(
        mediaPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      final file = File(mediaPath);
      // Check for video formats
      if (mediaPath.toLowerCase().endsWith('.mp4') ||
          mediaPath.toLowerCase().endsWith('.mov')) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
        );
      }
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }
}
