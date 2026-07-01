import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:provider/provider.dart';

/// Runs socket + provider refresh after login without blocking navigation.
class AuthSessionHelper {
  const AuthSessionHelper._();

  static void bootstrapAfterLogin(BuildContext context, String accessToken) {
    if (accessToken.isEmpty) return;

    unawaited(
      Future.microtask(() => SocketService().connect(accessToken)),
    );

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final storyController = Provider.of<StoryController>(
      context,
      listen: false,
    );

    unawaited(
      Future.microtask(() async {
        try {
          storyController.reset();
          await profileProvider.refreshProfile();
        } catch (_) {}
      }),
    );
  }

  static void connectSocket(String accessToken) {
    if (accessToken.isEmpty) return;
    unawaited(Future.microtask(() => SocketService().connect(accessToken)));
  }
}
