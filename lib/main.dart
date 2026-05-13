import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:gruve_app/features/profile/data/services/user_profile_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress verbose logs in release mode
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await dotenv.load(fileName: ".env"); // 👈 IMPORTANT
  await EnvironmentConfig.initialize(); // 👈 CRITICAL - Initialize environment config
  await SharedPreferences.getInstance(); // Ensure SharedPreferences is ready
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
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider(service: UserProfileService()),
        ),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => SavePostProvider()),
        ChangeNotifierProvider(create: (_) => LogoutProvider()),
        ChangeNotifierProvider(
          create: (_) => MessageProvider(MessageService()),
        ),
        ChangeNotifierProvider(
          lazy: false,

          create: (_) => UserProvider(
            UserRepositoryImpl(UserRemoteDataSource(ApiClient())),
          ),
        ),
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
