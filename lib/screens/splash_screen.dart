import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/intro/intro_screen.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isReady = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(AppAssets.splashVideo)
      ..initialize().then((_) {
        if (!mounted) return;

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

      // Check if user is already logged in
      final accessToken = await TokenStorage.getAccessToken();
      if (!mounted) return;
      
      if (accessToken != null && accessToken.isNotEmpty) {
        // User is logged in, navigate to Home screen
        debugPrint("🔑 Token found, navigating to Home screen");
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
        debugPrint("🔑 No token found, navigating to Intro screen");
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
