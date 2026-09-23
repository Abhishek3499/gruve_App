import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/auth/presentation/screens/sign_in_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState.isAuthenticated || authState.isLoggingOut) {
      return child;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    });

    return const Scaffold(backgroundColor: Colors.black);
  }
}
