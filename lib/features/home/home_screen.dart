import 'package:flutter/material.dart';
import 'package:gruve_app/features/message/screen/message_screen.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/features/story_preview/widgets/post/api/video_service.dart';
import 'package:gruve_app/features/story_preview/widgets/post/processing_dialog.dart';
import 'package:gruve_app/widgets/bottom_navigation/custom_bottom_navigation_bar.dart';
import 'package:gruve_app/features/home/widgets/video_feed.dart';
import 'package:gruve_app/features/home/controllers/video_feed_controller.dart';
import 'package:gruve_app/features/search/screens/search_screen.dart';
import 'package:gruve_app/features/camera/camera_handler.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isInBackground = false;
  final bool _isNavigatingAway = false;
  bool _isDisposed = false;
  VideoFeedController? _videoController;
  VideoService? _currentVideoService;

  static final RouteObserver<PageRoute> _routeObserver =
      RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    print("🏠 Home Screen initState called");
    PostShareFlowBridge.onShareStartProcessing = () {
      print("🏠 Home Screen: Share start processing callback triggered");
      if (mounted && !_isDisposed) _startVideoProcessing();
    };

    PostShareFlowBridge.onShareUploadError = () {
      if (!mounted || _isDisposed) return;
      _currentVideoService?.dispose();
      _currentVideoService = null;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    };

    _setupLifecycleObservers();
  }

  void _setupLifecycleObservers() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route is PageRoute) {
        _routeObserver.subscribe(this, route);
      }
    });
  }

  // ... AppLifecycleState logic ...
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused) _handleAppBackgrounded();
    if (state == AppLifecycleState.resumed) _handleAppResumed();
  }

  void _handleAppBackgrounded() {
    _pauseVideo('App backgrounded');
    _isInBackground = true;
  }

  void _handleAppResumed() {
    _isInBackground = false;
    if (_currentIndex == 0 && !_isNavigatingAway && !_isDisposed) {
      _resumeVideo('App resumed');
    }
  }

  void _startVideoProcessing() {
    _currentVideoService = VideoService();
    PostShareFlowBridge.setVideoService(_currentVideoService!);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: "Processing",
      pageBuilder: (context, anim1, anim2) {
        return StreamBuilder<double>(
          stream: _currentVideoService!.getProcessingProgress(),
          initialData: 0.0,
          builder: (context, snapshot) {
            final progress = snapshot.data ?? 0.0;
            if (progress >= 100) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Video Shared Successfully!")),
                );
              });
            }
            return ProcessingDialog(
              progress: progress,
              onCancel: () {
                _currentVideoService?.dispose();
                _currentVideoService = null;
                Navigator.pop(context);
              },
            );
          },
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, child) =>
          FadeTransition(opacity: anim1, child: child),
    );
  }

  void _onItemTapped(int index) async {
    if (index == _currentIndex || _isDisposed) return;

    if (index == 2) {
      final result = await CameraHandler.openCamera(context);
      if (result == 'start_processing') {
        _startVideoProcessing();
      }
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MessageScreen()),
      );
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    _handleTabChange(index);
  }

  void _handleTabChange(int newIndex) {
    print("🏠 Home Screen: Tab changed to $newIndex, previous: $_previousIndex");
    
    // Check if we're switching back to home tab and need refresh
    if (newIndex == 0 && PostShareFlowBridge.checkAndClearRefreshNeeded()) {
      print("🔄 Home Screen: Refreshing due to new post");
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          if (_videoController != null) {
            _videoController!.initVideos();
            print("✅ Home Screen: Video feed refreshed on tab change");
          } else {
            print("🔄 Home Screen: Video controller not available, but refresh triggered");
            // Force refresh by reinitializing the entire home screen
            setState(() {});
          }
        }
      });
    }
    
    if (newIndex == 0) {
      if (!_isInBackground && !_isNavigatingAway) {
        _resumeVideo('Tab changed to Home');
      }
    } else if (_previousIndex == 0) {
      _pauseVideo('Tab changed from Home');
    }
  }

  void _pauseVideo(String reason) => _videoController?.pauseCurrentVideo();
  void _resumeVideo(String reason) =>
      _videoController?.playVideo(_videoController!.currentIndex.value);

  List<Widget> _getScreens() {
    print("🏠 Home Screen: _getScreens called, _currentIndex: $_currentIndex");
    return [
      VideoFeed(
        selectedIndex: _currentIndex,
        onTabChanged: _onItemTapped,
        onControllerReady: (controller) {
          print("🏠 Home Screen: VideoFeed onControllerReady called!");
          _videoController = controller;
          PostShareFlowBridge.setVideoController(controller);
          print("🏠 Home Screen: Video controller ready and set to bridge");
        },
      ),
      const SearchScreen(),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print("🏠 Home Screen build called, _isDisposed: $_isDisposed");
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
    print("🏠 Home Screen: Disposing, clearing callbacks");
    PostShareFlowBridge.clearCallbacks();
    _isDisposed = true;
    _currentVideoService?.dispose();
    _videoController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver.unsubscribe(this);
    super.dispose();
  }
}
