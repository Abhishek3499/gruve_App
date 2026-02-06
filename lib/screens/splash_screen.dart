import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/intro/intro_screen.dart';

import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(AppAssets.splashVideo)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller
          ..setLooping(true)
          ..setVolume(0.0)
          ..play();
      });

    // ⏳ Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IntroScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _controller.value.isInitialized
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
              : const Center(child: CircularProgressIndicator()),

          Center(child: Image.asset(AppAssets.logoMain, width: 140)),

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
