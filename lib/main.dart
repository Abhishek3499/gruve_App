import 'package:flutter/material.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/splash_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // 👈 IMPORTANT
  await SharedPreferences.getInstance(); // Ensure SharedPreferences is ready
  runApp(MyApp());
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
      navigatorKey: rootNavigatorKey,

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
