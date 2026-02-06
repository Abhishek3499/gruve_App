import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/bottom_navigation/custom_bottom_navigation_bar.dart';
import 'package:gruve_app/features/home/widgets/video_feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          /// 🔥 VIDEO = PURE FULL SCREEN (NO SAFEAREA)
          if (_currentIndex == 0)
            VideoFeed(selectedIndex: _currentIndex, onTabChanged: _onItemTapped)
          else
            VideoBackground(
              videoPath: AppAssets.splashVideo,
              overlayOpacity: 0.85,
              child: const SizedBox.shrink(),
            ),

          /// 🔝 TOP SAFE AREA (agar future me buttons/text aaye)
          SafeArea(top: true, bottom: false, child: Container()),
        ],
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
