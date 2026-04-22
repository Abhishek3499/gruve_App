import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../../screens/auth/api/controllers/edit_profile_controller.dart';
import '../models/profile_model.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/personal_info_card.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late EditProfileController _controller;

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
    _controller = EditProfileController();
    _initializeControllers();
    // Fetch profile data when screen loads
    _fetchProfileData();
  }

  void _initializeControllers() {
    final profile = widget.initialProfile ?? _getDefaultProfile();

    _nameController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _emailController = TextEditingController(text: '');
    _usernameController = TextEditingController(text: '');
    _genderController = TextEditingController(text: '');
    _bioController = TextEditingController(text: '');
    _profileImagePath = profile.profileImagePath;
  }

  ProfileModel _getDefaultProfile() {
    return const ProfileModel(
      username: '__@nastasia__',
      bio: 'Digital creator | Photography enthusiast',
      email: 'anastasia.adams@example.com',
      profileImagePath: 'assets/search_screen_images/profile.png',
    );
  }

  Future<void> _fetchProfileData() async {
    await _controller.fetchProfile();
    if (_controller.profileResponse != null && mounted) {
      _populateFormFields();
    }
  }

  void _populateFormFields() {
    if (_controller.profileResponse == null) return;
    
    _nameController.text = _controller.fullName;
    _usernameController.text = _controller.username;
    _emailController.text = _controller.email;
    _phoneController.text = _controller.phone;
    _genderController.text = _controller.gender;
    _bioController.text = _controller.bio;
    _profileImagePath = _controller.currentProfilePicture;
    
    setState(() {});
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

  void _onImageChanged(String newPath) {
    setState(() {
      _profileImagePath = newPath;
    });
  }

  Future<void> _saveProfile() async {
    // Validate form
    final validationError = _controller.validateForm(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await _controller.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      profilePicture: _profileImagePath != AppAssets.profile ? _profileImagePath : null,
    );

    if (_controller.errorMessage == null && _controller.profileResponse != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A2C8F),
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
                  Positioned(
                    left: 16,
                    top: 15,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: SizedBox(
                          height: 60, // 👈 bigger tap area (important)
                          width: 50,
                          child: Center(
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: Image.asset(AppAssets.back),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 25,
                    left: 0,
                    right: 0,
                    child: Text(
                      _controller.profileResponse != null 
                          ? "Hey, ${_controller.fullName}"
                          : "Hey, User",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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

          /// DARK SECTION
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B182D),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(60, 50),
                      topRight: Radius.elliptical(60, 50),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 120,
                              left: 20,
                              right: 20,
                              bottom: 60,
                            ),
                            child: _buildContent(),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// Avatar
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

  Widget _buildContent() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${_controller.errorMessage}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF72008D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return PersonalInfoCard(
      nameController: _nameController,
      phoneController: _phoneController,
      emailController: _emailController,
      usernameController: _usernameController,
      genderController: _genderController,
      bioController: _bioController,
      onSave: _saveProfile,
      showEmail: _controller.showEmail,
      showPhone: _controller.showPhone,
      isUpdating: _controller.isUpdating,
    );
  }
}
