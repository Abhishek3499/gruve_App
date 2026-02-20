import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/screens/profile_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/assets.dart';
import '../models/profile_model.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/personal_info_card.dart';

/// Edit Profile Screen with Figma design implementation
class EditProfileScreen extends StatefulWidget {
  /// Initial profile data to populate fields
  final ProfileModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _genderController;
  late TextEditingController _bioController;

  // Current profile image path
  String _profileImagePath = AppAssets.profile;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  /// Initializes text controllers with default or provided profile data
  void _initializeControllers() {
    final profile = widget.initialProfile ?? _getDefaultProfile();

    _nameController = TextEditingController(text: 'Anastasia Adams');
    _phoneController = TextEditingController(text: '+1 234 567 8900');
    _emailController = TextEditingController(text: profile.email);
    _usernameController = TextEditingController(text: profile.username);
    _genderController = TextEditingController(text: 'Female');
    _bioController = TextEditingController(text: profile.bio);
    _profileImagePath = profile.profileImagePath;
  }

  /// Returns default profile model when no initial profile is provided
  ProfileModel _getDefaultProfile() {
    return const ProfileModel(
      username: '__@nastasia__',
      bio: 'Digital creator | Photography enthusiast',
      email: 'anastasia.adams@example.com',
      profileImagePath: 'assets/search_screen_images/profile.png',
    );
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Properly disposes all text controllers
  void _disposeControllers() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _genderController.dispose();
    _bioController.dispose();
  }

  /// Handles profile image change
  void _onImageChanged(String newPath) {
    setState(() {
      _profileImagePath = newPath;
    });
  }

  /// Validates and saves profile data
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = ProfileModel(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        profileImagePath: _profileImagePath,
      );

      _showSuccessMessage();
      _navigateBackWithResult(updatedProfile);
    }
  }

  /// Shows success message snackbar
  void _showSuccessMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigates back with updated profile data
  void _navigateBackWithResult(ProfileModel profile) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(profile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7A2C8F),
      body: Column(
        children: [
          /// 🔥 TOP GRADIENT AREA
          Container(
            height: 190,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF42174C), Color(0xFF7A2C8F)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  /// 🔙 Back Button
                  Positioned(
                    left: 16,
                    top: 15,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(AppAssets.back),
                      ),
                    ),
                  ),

                  /// Title
                  const Positioned(
                    top: 25,
                    left: 0,
                    right: 0,
                    child: Text(
                      "Hey, Kato",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔥 DARK SECTION WITH AVATAR OVERLAY
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                /// Dark curved background
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B182D),

                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(60, 50),
                      topRight: Radius.elliptical(60, 50),
                    ),
                  ),

                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 70,
                      left: 20,
                      right: 20,
                      bottom: 30,
                    ),
                    child: PersonalInfoCard(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      usernameController: _usernameController,
                      genderController: _genderController,
                      bioController: _bioController,
                      onSave: _saveProfile,
                    ),
                  ),
                ),

                /// Avatar (Perfect Above Curve)
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ProfileImagePicker(
                      currentImagePath: _profileImagePath,
                      onImageChanged: _onImageChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
