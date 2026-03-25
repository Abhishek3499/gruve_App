import 'package:flutter/material.dart';

import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/screens/splash_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

// Custom slide transition builder for consistent animations
class _SlideRightTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gruve',
      debugShowCheckedModeBanner: false,

      // 🔥 IMPORTANT: Prevent white flashes during navigation
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SlideRightTransition(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      navigatorObservers: [routeObserver],
      home: SplashScreen(),
    );
  }
}
