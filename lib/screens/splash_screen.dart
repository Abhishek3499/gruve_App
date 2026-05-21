import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/intro/intro_screen.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isReady = false;
  Timer? _navigationTimer;
  final DateTime _appStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    final videoInitStart = DateTime.now();
    developer.log('🚀 [PERF] Splash screen video initialization started', name: 'SplashScreen');
    
    _controller = VideoPlayerController.asset(AppAssets.splashVideo)
      ..initialize().then((_) {
        if (!mounted) return;
        
        final videoInitTime = DateTime.now().difference(videoInitStart);
        developer.log('🎥 [PERF] Video initialized in ${videoInitTime.inMilliseconds}ms', name: 'SplashScreen');

        setState(() {
          _isReady = true;
        });

        _controller
          ..setLooping(true)
          ..setVolume(0.0)
          ..play();
      });

    _navigationTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final totalStartupTime = DateTime.now().difference(_appStartTime);
      developer.log('🚀 [PERF] Total app startup time: ${totalStartupTime.inMilliseconds}ms', name: 'SplashScreen');

      // Check if user is already logged in
      final tokenCheckStart = DateTime.now();
      final accessToken = await TokenStorage.getAccessToken();
      final tokenCheckTime = DateTime.now().difference(tokenCheckStart);
      developer.log('🔑 [PERF] Token check completed in ${tokenCheckTime.inMilliseconds}ms', name: 'SplashScreen');
      
      if (!mounted) return;
      
      if (accessToken != null && accessToken.isNotEmpty) {
        // User is logged in, connect websocket and navigate to Home screen
        debugPrint("🔑 [Splash] 🔑 Token found, connecting websocket and navigating to Home screen");
        debugPrint("[Splash] Access token found");
        
        // 🔌 CONNECT WEBSOCKET FOR AUTO-LOGIN
        debugPrint("🔌 [Splash Auto-Login] 🔌 Connecting websocket with existing token");
        final websocketStart = DateTime.now();
        SocketService().connect(accessToken);
        final websocketTime = DateTime.now().difference(websocketStart);
        developer.log('🔌 [PERF] WebSocket connection initiated in ${websocketTime.inMilliseconds}ms', name: 'SplashScreen');
        debugPrint("✅ [Splash] ✅ WebSocket connection initiated");
        
        if (!mounted) return;
        debugPrint("🏠 [Splash] 🏠 Navigating to HomeScreen");
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionsBuilder: (_, animation, _, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      } else {
        // No token found, navigate to Intro screen
        debugPrint("[Splash] No token found, navigating to Intro screen");
        if (!mounted) return;
        debugPrint("🎯 [Splash] 🎯 Navigating to IntroScreen");
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) => const IntroScreen(),
            transitionsBuilder: (_, animation, _, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // important
      body: Stack(
        children: [
          // 🎥 VIDEO (FADE IN)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isReady ? 1 : 0,
            child: _isReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // 🔥 LOGO (SCALE + FADE)
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Opacity(
                  opacity: scale,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Image.asset(AppAssets.logoMain, width: 140),
            ),
          ),

          // 👇 BOTTOM TEXT (NO CHANGE)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/splash_screen_logo/image 43.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Made in India',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'Syncopate',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Powered by  ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Syncopate',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'Hardkore Tech',
                        style: TextStyle(
                          color: Color(0xFF9B4DFF),
                          fontSize: 11,
                          fontFamily: 'Syncopate',
                          fontWeight: FontWeight.w700,
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
    );
  }
}
