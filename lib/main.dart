import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/splash_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';

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
    return ChangeNotifierProvider(
      create: (context) => StoryController(),
      child: MaterialApp(
        title: 'Gruve',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,

        theme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.white,
          ),
        ),

        home: const SplashScreen(),
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
