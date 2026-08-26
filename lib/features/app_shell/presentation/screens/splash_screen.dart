import 'dart:developer' as developer;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_provider.dart';
import 'package:gruve_app/features/home/presentation/screens/home_screen.dart';
import 'package:gruve_app/features/app_shell/presentation/screens/intro_screen.dart';
import 'package:gruve_app/core/services/socket_service.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isReady = false;
  bool _didNavigate = false;
  final DateTime _appStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    final videoInitStart = DateTime.now();
    developer.log(
      '[PERF] Splash screen video initialization started',
      name: 'SplashScreen',
    );

    _controller = VideoPlayerController.asset(AppAssets.splashVideo);
    _initializeVideo(videoInitStart);

    Future<void>.microtask(_resolveInitialRoute);
  }

  Future<void> _initializeVideo(DateTime videoInitStart) async {
    try {
      await _controller.initialize();
      if (!mounted) return;

      final videoInitTime = DateTime.now().difference(videoInitStart);
      developer.log(
        '[PERF] Video initialized in ${videoInitTime.inMilliseconds}ms',
        name: 'SplashScreen',
      );

      setState(() => _isReady = true);

      await _controller.setLooping(true);
      await _controller.setVolume(0.0);
      await _controller.play();
    } catch (e) {
      AppLogger.d('[Splash] Video initialization skipped: $e');
    }
  }

  Future<void> _resolveInitialRoute() async {
    if (_didNavigate || !mounted) return;

    final totalStartupTime = DateTime.now().difference(_appStartTime);
    developer.log(
      '[PERF] Total app startup time: ${totalStartupTime.inMilliseconds}ms',
      name: 'SplashScreen',
    );

    final authState = AuthStateManager();
    final tokenCheckStart = DateTime.now();
    final accessToken = await authState.getActiveAccessToken();
    final tokenCheckTime = DateTime.now().difference(tokenCheckStart);
    developer.log(
      '[PERF] Auth state check completed in ${tokenCheckTime.inMilliseconds}ms',
      name: 'SplashScreen',
    );

    if (!mounted) return;

    if (authState.isAuthenticated &&
        accessToken != null &&
        accessToken.isNotEmpty) {
      AppLogger.d('[Splash] Authenticated session found');

      final websocketStart = DateTime.now();
      SocketService().connect(accessToken);
      final websocketTime = DateTime.now().difference(websocketStart);
      developer.log(
        '[PERF] WebSocket connection initiated in ${websocketTime.inMilliseconds}ms',
        name: 'SplashScreen',
      );

      // Single eager profile load (posts, highlights, avatar) — avoids duplicate profile_data.
      try {
        final profileProvider = context.read<ProfileProvider>();
        if (profileProvider.user == null) {
          unawaited(
            profileProvider.fetchProfileData(fetchUserReason: 'splash_eager_load'),
          );
        }
      } catch (e) {
        AppLogger.d('🚨 [Splash] Eager profile data pre-fetch failed: $e');
      }

      _navigateTo(const HomeScreen());
      return;
    }

    AppLogger.d('[Splash] No authenticated session, navigating to Intro screen');
    _navigateTo(const IntroScreen());
  }

  void _navigateTo(Widget screen) {
    if (_didNavigate || !mounted) return;
    _didNavigate = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
              child: Image.asset(AppAssets.logoMain, width: context.rw(140)),
            ),
          ),
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
                      width: context.rw(16),
                      height: context.rh(16),
                    ),
                    SizedBox(width: context.rw(3)),
                    Text(
                      'Made in India',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.rf(11),
                        fontFamily: 'Syncopate',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rh(6)),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Powered by  ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rf(11),
                          fontFamily: 'Syncopate',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'Hardkore Tech',
                        style: TextStyle(
                          color: const Color(0xFF9B4DFF),
                          fontSize: context.rf(11),
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
