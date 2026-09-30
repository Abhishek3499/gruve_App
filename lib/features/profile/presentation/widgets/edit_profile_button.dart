import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_response.dart';
import 'package:gruve_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:gruve_app/features/account/domain/entities/profile_model.dart';

/// Gradient "Edit Profile" pill button matching the screenshot design.
class EditProfileButton extends StatelessWidget {
  final ProfileModel? profile;
  final ValueChanged<EditProfileResponse>? onProfileUpdated;
  final VoidCallback? onTap;

  const EditProfileButton({
    super.key,
    this.profile,
    this.onProfileUpdated,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (onTap != null) {
            onTap!();
            return;
          }
          final result = await Navigator.push<EditProfileResponse>(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(initialProfile: profile),
            ),
          );

          if (result != null) {
            onProfileUpdated?.call(result);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 32.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE024C3), Color(0xFF8B5CF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_outlined, color: Colors.white, size: 14.0),
              SizedBox(width: 5),
              Text(
                "Edit Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined "Share Profile" pill button matching the screenshot design.
class ShareProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const ShareProfileButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 32.5,
          decoration: BoxDecoration(
            color: const Color(0xFF1B0B2E).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_outlined, color: Colors.white, size: 14.0),
              SizedBox(width: 5),
              Text(
                "Share Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
