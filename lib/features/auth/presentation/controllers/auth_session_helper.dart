import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_controller_notifier.dart';
import 'package:gruve_app/core/services/socket_service.dart';

/// Runs socket + provider refresh after login without blocking navigation.
class AuthSessionHelper {
  const AuthSessionHelper._();

  static void bootstrapAfterLogin(BuildContext context, String accessToken) {
    if (accessToken.isEmpty) return;

    unawaited(Future.microtask(() => SocketService().connect(accessToken)));

    final container = ProviderScope.containerOf(context, listen: false);

    unawaited(
      Future.microtask(() async {
        try {
          container.read(storyControllerProvider.notifier).reset();
          await container
              .read(profileNotifierProvider.notifier)
              .refreshProfile();
        } catch (_) {}
      }),
    );
  }

  static void connectSocket(String accessToken) {
    if (accessToken.isEmpty) return;
    unawaited(Future.microtask(() => SocketService().connect(accessToken)));
  }
}
