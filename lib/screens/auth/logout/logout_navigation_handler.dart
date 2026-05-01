import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/screens/auth/logout/logout_provider.dart';
import 'package:gruve_app/screens/auth/screens/sign_in_screen.dart';

/// Widget to handle logout navigation safely
class LogoutNavigationHandler extends StatefulWidget {
  final Widget child;

  const LogoutNavigationHandler({super.key, required this.child});

  @override
  State<LogoutNavigationHandler> createState() => _LogoutNavigationHandlerState();
}

class _LogoutNavigationHandlerState extends State<LogoutNavigationHandler> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LogoutProvider>(
      builder: (context, logoutProvider, child) {
        // Listen for navigation trigger
        if (logoutProvider.shouldNavigate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutNavigation(context, logoutProvider);
          });
        }
        
        return child!;
      },
      child: widget.child,
    );
  }

  void _handleLogoutNavigation(BuildContext context, LogoutProvider logoutProvider) {
    debugPrint('🚀 [LogoutNavigation] Navigating to SignIn screen...');

    // Use rootNavigatorKey for safe navigation regardless of context
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const SignInScreen(),
      ),
      (route) => false,
    );

    // Reset navigation flag
    logoutProvider.resetNavigationFlag();
  }
}
