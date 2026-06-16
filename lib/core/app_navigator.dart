import 'package:flutter/material.dart';

/// Root [NavigatorState] for showing overlays after popping nested routes
/// (e.g. share sheet on home after camera + preview).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Global key to access ScaffoldMessengerState from anywhere (e.g., across async gaps in providers)
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
