import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:gruve_app/screens/auth/logout/logout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/splash_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/message/providers/message_provider.dart';
import 'package:gruve_app/features/message/services/message_service.dart';
import 'package:gruve_app/features/message/presentation/provider/user_provider.dart';
import 'package:gruve_app/features/message/data/repository/user_repository_impl.dart';
import 'package:gruve_app/features/message/data/datasource/user_remote_datasource.dart';
import 'package:gruve_app/core/network/api_client.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  final appInitStart = DateTime.now();
  developer.log('🚀 [PERF] App initialization started', name: 'Main');
  
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress verbose logs in release mode
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Set preferred orientations for better performance
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final envLoadStart = DateTime.now();
  await dotenv.load(fileName: ".env"); // 👈 IMPORTANT
  final envLoadTime = DateTime.now().difference(envLoadStart);
  developer.log('⚙️ [PERF] Environment loaded in ${envLoadTime.inMilliseconds}ms', name: 'Main');

  final sharedPrefsStart = DateTime.now();
  await SharedPreferences.getInstance(); // Ensure SharedPreferences is ready
  final sharedPrefsTime = DateTime.now().difference(sharedPrefsStart);
  developer.log('💾 [PERF] SharedPreferences initialized in ${sharedPrefsTime.inMilliseconds}ms', name: 'Main');

  final totalInitTime = DateTime.now().difference(appInitStart);
  developer.log('🚀 [PERF] Total main() initialization time: ${totalInitTime.inMilliseconds}ms', name: 'Main');

  // Start frame performance monitoring
  if (kDebugMode) {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        if (timing.totalSpan.inMicroseconds > 16666) { // > 16.66ms = < 60 FPS
          developer.log('⚠️ [PERF] Frame drop: ${timing.totalSpan.inMicroseconds}μs', name: 'FrameTiming');
        }
      }
    });
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateManager()),
        ChangeNotifierProvider(create: (context) => StoryController()),
        ChangeNotifierProvider(create: (_) => HighlightFlowProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => SavePostProvider()),
        ChangeNotifierProvider(create: (_) => LogoutProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider(MessageService())),
        ChangeNotifierProvider(create: (_) => UserProvider(UserRepositoryImpl(UserRemoteDataSource(ApiClient())))),
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
