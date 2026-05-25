import 'package:flutter/material.dart';
import 'package:gruve_app/core/auth/auth_guard.dart';
import 'package:gruve_app/core/routing/app_route_names.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/screens/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const initialRoute = AppRouteNames.splash;

  static Map<String, WidgetBuilder> get routes => {
    AppRouteNames.splash: (_) => const SplashScreen(),
    AppRouteNames.profile: (_) => const AuthGuard(child: ProfileScreen()),
  };
}
