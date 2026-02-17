import 'package:flutter/material.dart';
import 'package:gruve_app/features/home/home_screen.dart';
import 'package:gruve_app/screens/intro/intro_screen.dart';
import 'package:gruve_app/screens/splash_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gruve',
      debugShowCheckedModeBanner: false,

      // 🔥 THIS IS IMPORTANT
      navigatorObservers: [routeObserver],

      home: const HomeScreen(),
    );
  }
}
