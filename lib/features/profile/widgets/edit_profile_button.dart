import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/api/models/edit_profile_response.dart';

import '../screens/edit_profile_screen.dart';
import '../models/profile_model.dart';

class EditProfileButton extends StatelessWidget {
  final ProfileModel? profile;
  final ValueChanged<EditProfileResponse>? onProfileUpdated;

  const EditProfileButton({
    super.key,
    this.profile,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
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
      child: Container(
        height: 40,
        width: 160,
        padding: const EdgeInsets.only(left: 16, right: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withAlpha(102),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  AppAssets.editprofile,
                  width: 18,
                  height: 18,
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
