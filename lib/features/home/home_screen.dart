import 'package:flutter/material.dart';
import 'package:gruve_app/features/message/screen/message_screen.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/features/search/screens/search_screen.dart';
import 'package:gruve_app/features/story_preview/api/post/api/video_service.dart';
import 'package:gruve_app/features/story_preview/api/post/processing_dialog.dart';
import 'package:gruve_app/widgets/bottom_navigation/custom_bottom_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/home/controllers/video_feed_controller.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/home/widgets/video_feed.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/screens/auth/screens/sign_in_screen.dart';
import 'package:gruve_app/features/camera/camera_handler.dart';

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
  
  // ✅ CRITICAL: Cache screens to prevent rebuilds
  late final List<Widget> _screens;

  // Double tap detection for Home tab with smooth animations
  int? _lastHomeTapTime;
  static const int _doubleTapThreshold = 400; // milliseconds
  bool _isScrollingToTop = false;
  bool _cameraFlowInProgress = false;
  bool _videoProcessingDismissScheduled = false;

  /// True once the share processing [showGeneralDialog] route is on the stack.
  bool _shareProcessingOverlayVisible = false;

  static final RouteObserver<PageRoute> _routeObserver =
      RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint("🏠 Home Screen initState called");
    }
    
    // ✅ Initialize screens ONCE
    _screens = [
      VideoFeed(
        selectedIndex: _currentIndex,
        onTabChanged: _onItemTapped,
        onControllerReady: (controller) {
          if (kDebugMode) {
            debugPrint("🏠 Home Screen: VideoFeed onControllerReady called!");
          }
          _videoController = controller;
          PostShareFlowBridge.setVideoController(controller);
          if (kDebugMode) {
            debugPrint(
              "🏠 Home Screen: Video controller ready and set to bridge",
            );
          }
        },
      ),
      const SearchScreen(),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const ProfileScreen(),
    ];
    
    PostShareFlowBridge.onShareStartProcessing = () {
      if (kDebugMode) {
        debugPrint("🏠 Home Screen: Share start processing callback triggered");
      }
      if (mounted && !_isDisposed) _startVideoProcessing();
    };

    PostShareFlowBridge.onShareUploadError = () {
      if (!mounted || _isDisposed) return;
      _currentVideoService?.dispose();
      _currentVideoService = null;
      // Only dismiss our processing dialog. [Navigator.maybePop] without a dialog
      // on top pops [HomeScreen] (auth stack below looks like logout).
      if (_shareProcessingOverlayVisible) {
        _shareProcessingOverlayVisible = false;
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload failed. Check your connection or try a smaller video.',
          ),
        ),
      );
    };

    PostShareFlowBridge.onRequestShowHomeFeed = _ensureHomeFeedTab;
    PostShareFlowBridge.onRequestShowProfileTab = _ensureProfileTab;

    _setupLifecycleObservers();
  }

  /// Video feed is tab index 0; opening + or finishing a share must show this tab,
  /// not Profile (4) or Search (1) left selected under the route stack.
  void _ensureHomeFeedTab() {
    if (!mounted || _isDisposed || _currentIndex == 0) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = 0;
    });
    _handleTabChange(0);
  }

  void _ensureProfileTab() {
    if (!mounted || _isDisposed || _currentIndex == 4) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = 4;
    });
    _handleTabChange(4);
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
    if (kDebugMode) {
      debugPrint("📱 App lifecycle state: $state");
    }
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
    _videoProcessingDismissScheduled = false;
    _shareProcessingOverlayVisible = false;
    _currentVideoService = VideoService();
    PostShareFlowBridge.setVideoService(_currentVideoService!);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final dialogFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: "Processing",
      pageBuilder: (dialogRouteContext, anim1, anim2) {
        return StreamBuilder<double>(
          stream: _currentVideoService!.getProcessingProgress(),
          initialData: 0.0,
          builder: (context, snapshot) {
            final progress = snapshot.data ?? 0.0;
            // Stream keeps emitting at 100%; only dismiss once or we pop past the dialog.
            if (progress >= 100 && !_videoProcessingDismissScheduled) {
              _videoProcessingDismissScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (nav.canPop()) nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Video Shared Successfully!")),
                );
              });
            }
            return ProcessingDialog(
              progress: progress,
              onCancel: () {
                _currentVideoService?.dispose();
                _currentVideoService = null;
                Navigator.of(dialogRouteContext).pop();
              },
            );
          },
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, child) =>
          FadeTransition(opacity: anim1, child: child),
    );

    dialogFuture.whenComplete(() {
      if (!mounted || _isDisposed) return;
      _shareProcessingOverlayVisible = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      _shareProcessingOverlayVisible = true;
    });
  }

  void _onItemTapped(int index) async {
    if (_isDisposed) return;

    // Handle Home tab double tap logic with smooth animations
    if (index == 0) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (_currentIndex == 0) {
        // Already on Home tab - check for double tap
        if (_lastHomeTapTime != null &&
            currentTime - _lastHomeTapTime! < _doubleTapThreshold) {
          // Double tap detected - refresh feed smoothly
          _lastHomeTapTime = null; // Reset to prevent triple taps
          await _handleHomeTabDoubleTap();
          return;
        } else {
          // Single tap on Home tab - scroll to top smoothly
          _lastHomeTapTime = currentTime;
          await _scrollToTop();
          return;
        }
      } else {
        // Navigating to Home tab from another tab
        _lastHomeTapTime = currentTime;
        setState(() {
          _previousIndex = _currentIndex;
          _currentIndex = index;
        });
        _handleTabChange(index);
        return;
      }
    }

    if (index == _currentIndex) return;

    if (index == 2) {
      if (_cameraFlowInProgress) return;

      // Check if user is authenticated before opening camera
      final token = await TokenStorage.getAccessToken();
      if (!mounted || _isDisposed) return;
      if (token == null || token.isEmpty) {
        // Navigate to sign in screen instead of just showing snackbar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
        return;
      }

      _ensureHomeFeedTab();

      _cameraFlowInProgress = true;
      try {
        final result = await CameraHandler.openCamera(context);
        if (!mounted || _isDisposed) return;
        if (result == 'start_processing') {
          _startVideoProcessing();
        }
      } finally {
        _cameraFlowInProgress = false;
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
    if (kDebugMode) {
      debugPrint(
        "🏠 Home Screen: Tab changed to $newIndex, previous: $_previousIndex",
      );
    }

    // Check if we're switching back to home tab and need refresh
    if (newIndex == 0 && PostShareFlowBridge.checkAndClearRefreshNeeded()) {
      if (kDebugMode) {
        debugPrint("🔄 Home Screen: Refreshing due to new post");
      }
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          if (_videoController != null) {
            _videoController!.initVideos(refresh: true);
            if (kDebugMode) {
              debugPrint("✅ Home Screen: Video feed refreshed on tab change");
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                "🔄 Home Screen: Video controller not available, but refresh triggered",
              );
            }
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

  // Smooth scroll to top functionality
  Future<void> _scrollToTop() async {
    if (_isScrollingToTop || _videoController == null) return;

    _isScrollingToTop = true;

    try {
      if (_videoController!.posts.isNotEmpty) {
        // Smooth animation to first video
        for (int i = _videoController!.currentIndex.value; i >= 0; i--) {
          _videoController!.playVideo(i);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } finally {
      _isScrollingToTop = false;
    }
  }

  // Handle double tap refresh with smooth animation
  Future<void> _handleHomeTabDoubleTap() async {
    if (_isScrollingToTop) return;

    // First scroll to top smoothly
    await _scrollToTop();

    // Small delay to ensure scroll completes
    await Future.delayed(const Duration(milliseconds: 200));

    // Then refresh feed
    if (_videoController != null) {
      await _videoController!.initVideos(refresh: true);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint("🏠 Home Screen build called, _isDisposed: $_isDisposed");
    }
    if (_isDisposed) return const SizedBox.shrink();
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint("🏠 Home Screen: Disposing, clearing callbacks");
    }
    PostShareFlowBridge.clearCallbacks();
    _isDisposed = true;
    _currentVideoService?.dispose();
    // [VideoFeedController] is owned and disposed by [VideoFeed]; do not dispose here
    // or ValueNotifiers are disposed twice when IndexedStack children unmount.
    _videoController = null;
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver.unsubscribe(this);
    super.dispose();
  }
}
