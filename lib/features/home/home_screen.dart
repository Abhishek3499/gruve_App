import 'package:flutter/material.dart';

import 'package:gruve_app/features/notification/screens/notification_screen.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/widgets/video_background.dart';
import 'package:gruve_app/widgets/bottom_navigation/custom_bottom_navigation_bar.dart';
import 'package:gruve_app/features/home/widgets/video_feed.dart';
import 'package:gruve_app/features/home/widgets/video_overlay.dart';
import 'package:gruve_app/features/search/screens/search_screen.dart';

import 'package:video_player/video_player.dart';

/// Professional HomeScreen with comprehensive video lifecycle management
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  int _currentIndex = 0;
  String _selectedTab = 'For you';
  int _previousIndex = 0;
  bool _isInBackground = false;
  bool _isNavigatingAway = false;
  bool _isDisposed = false;

  // Global route observer for navigation tracking
  static final RouteObserver<PageRoute> _routeObserver =
      RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    _setupLifecycleObservers();
  }

  void _setupLifecycleObservers() {
    WidgetsBinding.instance.addObserver(this);

    // Register route observer after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route is PageRoute) {
        _routeObserver.subscribe(this, route);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isDisposed) return; // Prevent actions after disposal

    switch (state) {
      case AppLifecycleState.paused:
        _handleAppBackgrounded();
        break;

      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;

      case AppLifecycleState.detached:
        _handleAppDetached();
        break;

      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;

      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppBackgrounded() {
    _pauseVideo('App backgrounded');
    _isInBackground = true;
  }

  void _handleAppResumed() {
    _isInBackground = false;
    // Only resume if we're on home tab and not navigating away
    if (_currentIndex == 0 && !_isNavigatingAway && !_isDisposed) {
      _resumeVideo('App resumed');
    }
  }

  void _handleAppDetached() {
    _pauseVideo('App detached');
  }

  void _handleAppInactive() {
    _pauseVideo('App inactive');
  }

  void _handleAppHidden() {
    _pauseVideo('App hidden');
    _isInBackground = true;
  }

  @override
  void didPush() {
    if (_isDisposed) return;
    _isNavigatingAway = true;
    _pauseVideo('Route pushed');
  }

  @override
  void didPop() {
    if (_isDisposed) return;
    _isNavigatingAway = false;
    // Only resume if we're back on home tab
    if (_currentIndex == 0) {
      _resumeVideo('Route popped');
    }
  }

  @override
  void didPushNext() {
    if (_isDisposed) return;
    _isNavigatingAway = true;
    _pauseVideo('Route pushed next');
  }

  @override
  void didPopNext() {
    if (_isDisposed) return;
    _isNavigatingAway = false;
    if (_currentIndex == 0) {
      _resumeVideo('Route popped next');
    }
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex || _isDisposed) {
      return; // Prevent duplicate actions
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    _handleTabChange(index);
  }

  void _handleTabChange(int newIndex) {
    if (newIndex == 0) {
      // User is going to Home tab
      if (!_isInBackground && !_isNavigatingAway) {
        _resumeVideo('Tab changed to Home');
      }
    } else if (_previousIndex == 0) {
      // User is leaving Home tab
      _pauseVideo('Tab changed from Home');
    }
  }

  void _pauseVideo(String reason) {
    if (_isDisposed) return;

    final controller = _getVideoController();
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying) {
      controller.pause();
      debugPrint('Video paused: $reason');
    }
  }

  void _resumeVideo(String reason) {
    if (_isDisposed) return;

    final controller = _getVideoController();
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isPlaying) {
      controller.play();
      debugPrint('Video resumed: $reason');
    }
  }

  VideoPlayerController? _getVideoController() {
    // Access shared controller from VideoBackground
    return VideoBackgroundState.sharedController;
  }

  void _onTabChanged(String tab) {
    if (_isDisposed) return;

    setState(() {
      _selectedTab = tab;
    });
  }

  List<Widget> _getScreens() {
    return [
      // Home Tab (0)
      Stack(
        children: [
          // VideoBackground(
          //   videoPath: AppAssets.splashVideo,
          //   overlayOpacity: 0.45,
          //   child: const SizedBox.shrink(),
          // ),
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
    if (_isDisposed) return const SizedBox.shrink();

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

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _pauseVideo('HomeScreen disposed');

    WidgetsBinding.instance.removeObserver(this);
    _routeObserver.unsubscribe(this);

    super.dispose();
  }
}
