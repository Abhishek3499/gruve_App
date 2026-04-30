import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/splash_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress verbose logs in release mode
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await dotenv.load(fileName: ".env"); // 👈 IMPORTANT
  await SharedPreferences.getInstance(); // Ensure SharedPreferences is ready
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StoryController()),
        ChangeNotifierProvider(create: (_) => HighlightFlowProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
      ],
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
        routes: {'/profile': (_) => const ProfileScreen()},
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
