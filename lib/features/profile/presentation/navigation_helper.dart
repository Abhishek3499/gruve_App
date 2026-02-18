import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/models/user_model.dart';
import 'package:gruve_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:gruve_app/features/profile/presentation/screens/my_profile_screen.dart';

class NavigationHelper {
  static void navigateToUserProfile(BuildContext context, UserModel user) {
    if (!context.mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: user),
      ),
    );
  }

  static void navigateToMyProfile(BuildContext context) {
    if (!context.mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProfileScreen(),
      ),
    );
  }

  static void navigateToUserProfileWithReplacement(BuildContext context, UserModel user) {
    if (!context.mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: user),
      ),
    );
  }

  static void navigateToMyProfileWithReplacement(BuildContext context) {
    if (!context.mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProfileScreen(),
      ),
    );
  }

  static void navigateToUserProfileAndClearStack(BuildContext context, UserModel user) {
    if (!context.mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: user),
      ),
      (route) => false,
    );
  }

  static void navigateToMyProfileAndClearStack(BuildContext context) {
    if (!context.mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProfileScreen(),
      ),
      (route) => false,
    );
  }

  // Safe navigation wrapper for ListView.builder (for other users)
  static Widget wrapWithUserProfileNavigation({
    required BuildContext context,
    required UserModel user,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => navigateToUserProfile(context, user),
      child: child,
    );
  }

  // For profile image/avatar specifically (for other users)
  static Widget buildTappableUserAvatar({
    required BuildContext context,
    required UserModel user,
    double radius = 25.0,
  }) {
    return GestureDetector(
      onTap: () => navigateToUserProfile(context, user),
      child: CircleAvatar(
        backgroundImage: AssetImage(user.profileImage),
        radius: radius,
      ),
    );
  }

  // For username specifically (for other users)
  static Widget buildTappableUsername({
    required BuildContext context,
    required UserModel user,
    TextStyle? textStyle,
  }) {
    return GestureDetector(
      onTap: () => navigateToUserProfile(context, user),
      child: Text(
        user.username,
        style: textStyle ?? const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Legacy method for backward compatibility
  static void navigateToProfile(BuildContext context, UserModel user) {
    if (user.isCurrentUser) {
      navigateToMyProfile(context);
    } else {
      navigateToUserProfile(context, user);
    }
  }
}
