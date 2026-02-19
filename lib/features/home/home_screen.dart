import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/camera/screen/camera_screen.dart';
import 'package:gruve_app/features/notification/screens/notification_screen.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/bottom_navigation/custom_bottom_navigation_bar.dart';
import 'package:gruve_app/features/home/widgets/video_feed.dart';
import 'package:gruve_app/features/home/widgets/video_overlay.dart';
import 'package:gruve_app/features/search/screens/search_screen.dart';

import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedTab = 'For you';
  int _previousIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      // Pause video before opening camera
      final controller = _getSharedVideoController();
      controller?.pause();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen()),
      ).then((_) {
        // Resume video when coming back
        if (_currentIndex == 0) {
          controller?.play();
        }
      });

      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    _manageVideoController(index);
  }

  void _manageVideoController(int newIndex) {
    // Get access to the shared video controller
    final controller = _getSharedVideoController();

    if (controller != null && controller.value.isInitialized) {
      if (newIndex == 0) {
        // User is going to Home tab - resume video
        controller.play();
      } else if (_previousIndex == 0) {
        // User is leaving Home tab - pause video
        controller.pause();
      }
    }
  }

  VideoPlayerController? _getSharedVideoController() {
    // Access the shared controller from VideoBackground
    return VideoBackgroundState.sharedController;
  }

  void _onTabChanged(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  List<Widget> _getScreens() {
    return [
      // Home Tab (0)
      Stack(
        children: [
          VideoBackground(
            videoPath: AppAssets.splashVideo,
            overlayOpacity: 0.45,
            child: const SizedBox.shrink(),
          ),
          VideoFeed(selectedIndex: _currentIndex, onTabChanged: _onItemTapped),
          VideoOverlay(selectedTab: _selectedTab, onTabChanged: _onTabChanged),
        ],
      ),

      // Search Tab (1)
      const SearchScreen(),

      // Create Tab (2)
      Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Create',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),

      // Notifications Tab (3)
      const NotificationScreen(),

      // Profile Tab (4)
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: IndexedStack(index: _currentIndex, children: _getScreens()),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
