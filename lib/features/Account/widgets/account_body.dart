import 'package:flutter/material.dart';
import '../../profile/widgets/personal_info_card.dart';
import '../../profile/widgets/profile_image_picker.dart';
import '../widgets/account_footer.dart'; // ✅ add this

/// Main body widget for Account screen
class AccountBody extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController genderController;
  final TextEditingController bioController;
  final String profileImagePath;

  const AccountBody({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.usernameController,
    required this.genderController,
    required this.bioController,
    required this.profileImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// 🔥 Dark Rounded Container
        Container(
          margin: const EdgeInsets.only(top: 20), // 👈 moved upward (was 60)
          decoration: const BoxDecoration(
            color: Color(0xFF1B182D),
            borderRadius: BorderRadius.only(
              topLeft: Radius.elliptical(60, 50),
              topRight: Radius.elliptical(60, 50),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 85, // 👈 adjust avatar space
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PersonalInfoCard(
                nameController: nameController,
                phoneController: phoneController,
                emailController: emailController,
                usernameController: usernameController,
                genderController: genderController,
                bioController: bioController,
                onSave: () {},
                showEditIcon: false,
                showUpdateButton: false,
                isReadOnly: true,
              ),

              const SizedBox(height: 20),

              const AccountFooter(),
            ],
          ),
        ),

        /// 🔥 Avatar
        Positioned(
          top: -40, // 👈 shift avatar upward
          left: 0,
          right: 0,
          child: Center(
            child: ProfileImagePicker(
              currentImagePath: profileImagePath,
              onImageChanged: (_) {},
              showEditButton: false,
            ),
          ),
        ),
      ],
    );
  }
}
