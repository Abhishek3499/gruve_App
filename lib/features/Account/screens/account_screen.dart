import 'package:flutter/material.dart';
import 'package:gruve_app/features/Account/widgets/account_body.dart';
import 'package:gruve_app/features/Account/widgets/account_footer.dart';
import 'package:gruve_app/features/Account/widgets/account_header.dart';
import 'package:gruve_app/features/profile/models/profile_model.dart';
import '../../../../core/assets.dart';

/// Account Screen with professional widget separation
class AccountScreen extends StatefulWidget {
  final ProfileModel? initialProfile;

  const AccountScreen({super.key, this.initialProfile});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _genderController;
  late TextEditingController _bioController;
  String _profileImagePath = AppAssets.profile;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? _defaultProfile();

    _nameController = TextEditingController(text: 'Anastasia Adams');
    _phoneController = TextEditingController(text: '+1 234 567 8900');
    _emailController = TextEditingController(text: profile.email);
    _usernameController = TextEditingController(text: profile.username);
    _genderController = TextEditingController(text: 'Female');
    _bioController = TextEditingController(text: profile.bio);
    _profileImagePath = profile.profileImagePath;
  }

  ProfileModel _defaultProfile() {
    return const ProfileModel(
      username: '__@nastasia__',
      bio: 'Digital creator | Photography enthusiast',
      email: 'anastasia.adams@example.com',
      profileImagePath: 'assets/search_screen_images/profile.png',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _genderController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A2C8F),
      body: Column(
        children: [
          /// Header
          const AccountHeader(),

          /// Main Body
          Expanded(
            child: AccountBody(
              nameController: _nameController,
              phoneController: _phoneController,
              emailController: _emailController,
              usernameController: _usernameController,
              genderController: _genderController,
              bioController: _bioController,
              profileImagePath: _profileImagePath,
            ),
          ),

          /// Footer
        ],
      ),
    );
  }
}
