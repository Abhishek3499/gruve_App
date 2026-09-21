import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:gruve_app/core/navigation/app_navigator.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/theme/app_theme.dart';
import 'package:gruve_app/core/navigation/app_routes.dart';
import 'package:gruve_app/core/storage/hive_service.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';

import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local cache storage
  try {
    await HiveService().init();
  } catch (e) {
    AppLogger.d('🚨 [Main] HiveService initialization failed: $e');
  }

  // AppLogger suppresses all output in release/profile builds.
  // This override silences any remaining Flutter framework debugPrint calls.
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;

  try {
    await EnvironmentConfig.initialize(); // 👈 CRITICAL - Initialize environment config
  } catch (e) {
    AppLogger.d('🚨 [Main] EnvironmentConfig initialization failed: $e');
  }

  try {
    await TokenStorage.init(); // Ensure SharedPreferences and cached userId are ready
  } catch (e) {
    AppLogger.d('🚨 [Main] TokenStorage initialization failed: $e');
  }

  final authStateManager = AuthStateManager();
  try {
    await authStateManager.initialize();

    // Eagerly prime ProfileIdentityService with the logged-in user ID for instant synchronous resolution!
    if (authStateManager.currentUserId != null) {
      ProfileIdentityService.instance.primeLoggedInUserId(
        authStateManager.currentUserId,
      );
    }
  } catch (e) {
    AppLogger.d('🚨 [Main] AuthStateManager initialization failed: $e');
  }

  runApp(ProviderScope(child: MyApp(authStateManager: authStateManager)));
}

class MyApp extends StatelessWidget {
  final AuthStateManager? authStateManager;

  const MyApp({super.key, this.authStateManager});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: authStateManager ?? AuthStateManager(),
        ),
      ],
      child: MaterialApp(
        title: 'Gruve',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,

        theme: AppTheme.darkTheme,

        initialRoute: AppRoutes.initialRoute,
        routes: AppRoutes.routes,
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
