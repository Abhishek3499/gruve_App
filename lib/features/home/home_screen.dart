import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/bottom_navigation/custom_bottom_navigation_bar.dart';
import 'package:gruve_app/features/home/widgets/video_feed.dart';
import 'package:gruve_app/features/home/widgets/video_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedTab = 'For you';

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabChanged(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Video
          VideoBackground(
            videoPath: AppAssets.splashVideo,
            overlayOpacity: _currentIndex == 0 ? 0.45 : 0.85,
            child: const SizedBox.shrink(),
          ),

          // ✅ Video Feed (Add this)
          if (_currentIndex == 0)
            VideoFeed(
              selectedIndex: _currentIndex,
              onTabChanged: _onItemTapped,
            ),

          // Overlay (Top Tabs + UI)
          if (_currentIndex == 0)
            VideoOverlay(
              selectedTab: _selectedTab,
              onTabChanged: _onTabChanged,
            ),
        ],
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
