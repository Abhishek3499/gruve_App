import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/routing/app_routes.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/highlights_create/controller/highlight_create_controller.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:gruve_app/features/user_profile/data/services/user_profile_service.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:gruve_app/features/auth/logout/logout_provider.dart';
import 'package:gruve_app/features/auth/presentation/provider/auth_ui_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/core/storage/hive_service.dart';

import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/message/providers/message_provider.dart';
import 'package:gruve_app/features/message/services/message_service.dart';
import 'package:gruve_app/features/message/controllers/conversation_controller.dart';
import 'package:gruve_app/features/message/presentation/provider/user_provider.dart';
import 'package:gruve_app/features/message/data/repository/user_repository_impl.dart';
import 'package:gruve_app/features/message/data/datasource/user_remote_datasource.dart';
import 'package:gruve_app/core/network/api_client.dart';
import 'package:gruve_app/features/notification/providers/notification_provider.dart';
import 'package:gruve_app/features/story_preview/providers/drafts_provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    await SharedPreferences.getInstance(); // Ensure SharedPreferences is ready
  } catch (e) {
    AppLogger.d('🚨 [Main] SharedPreferences initialization failed: $e');
  }

  final authStateManager = AuthStateManager();
  try {
    await authStateManager.initialize();
  } catch (e) {
    AppLogger.d('🚨 [Main] AuthStateManager initialization failed: $e');
  }

  runApp(MyApp(authStateManager: authStateManager));
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
        ChangeNotifierProvider.value(value: StoryStateController()),
        ChangeNotifierProvider(
          create: (_) => HighlightStateManager()..loadFromPreferences(),
        ),
        ChangeNotifierProxyProvider<HighlightStateManager, StoryController>(
          create: (_) => StoryController(),
          update: (_, stateManager, controller) =>
              (controller ?? StoryController())
                ..attachHighlightStateManager(stateManager),
        ),
        ChangeNotifierProxyProvider<HighlightStateManager, HighlightController>(
          create: (_) => HighlightController(),
          update: (_, stateManager, controller) =>
              (controller ?? HighlightController())
                ..attachStateManager(stateManager),
        ),
        ChangeNotifierProxyProvider2<
          HighlightController,
          HighlightStateManager,
          HighlightCreateController
        >(
          create: (context) => HighlightCreateController(
            highlightController: context.read<HighlightController>(),
            stateManager: context.read<HighlightStateManager>(),
          ),
          update: (_, highlightController, stateManager, controller) =>
              controller ??
              HighlightCreateController(
                highlightController: highlightController,
                stateManager: stateManager,
              ),
        ),
        ChangeNotifierProvider(create: (_) => HighlightFlowProvider()),
        ChangeNotifierProxyProvider<HighlightStateManager, ProfileProvider>(
          create: (context) => ProfileProvider(
            highlightStateManager: context.read<HighlightStateManager>(),
          ),
          update: (_, stateManager, provider) =>
              provider ?? ProfileProvider(highlightStateManager: stateManager),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider(service: UserProfileService()),
        ),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => SavePostProvider()),
        ChangeNotifierProvider(create: (_) => LogoutProvider()),
        ChangeNotifierProvider(create: (_) => AuthUiProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => MessageProvider(MessageService()),
        ),
        ChangeNotifierProvider(
          lazy: true,
          create: (_) => ConversationController(MessageService()),
        ),
        ChangeNotifierProvider(
          lazy: true,
          create: (_) => UserProvider(
            UserRepositoryImpl(UserRemoteDataSource(ApiClient())),
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DraftsProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Gruve',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,

        theme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.white,
          ),
        ),

        initialRoute: AppRoutes.initialRoute,
        routes: AppRoutes.routes,
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
