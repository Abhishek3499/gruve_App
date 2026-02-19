import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../screens/edit_profile_screen.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
      },
      child: Container(
        height: 40,
        width: 160,
        padding: const EdgeInsets.only(left: 16, right: 5), // 👈 important
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// 🔥 LEFT TEXT (Now starts properly)
            const Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            /// 🔥 Right Circle Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.4),
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
