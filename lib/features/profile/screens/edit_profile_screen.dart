import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../../screens/auth/api/controllers/edit_profile_controller.dart';
import '../models/profile_model.dart';
import '../widgets/personal_info_card.dart';
import '../widgets/profile_image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

    if (!mounted) return;

    if (_controller.profileResponse != null) {
      _populateFormFields();
    } else {
      setState(() {});
    }
  }

  void _populateFormFields() {
    if (_controller.profileResponse == null) {
      return;
    }

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

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final fullname = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim().isEmpty
        ? null
        : _bioController.text.trim();

    final validationError = _controller.validateForm(
      fullName: fullname,
      username: username,
      bio: bio,
    );

    if (validationError != null) {
      _showSnackBar(validationError, Colors.red);
      return;
    }

    final currentFullName = _controller.fullName.trim();
    final currentUsername = _controller.username.trim();
    final currentBio = _controller.bio.trim();
    final currentProfilePicture = _controller.currentProfilePicture.trim();
    final hasChanges =
        fullname != currentFullName ||
        username != currentUsername ||
        (bio ?? '') != currentBio ||
        _profileImagePath.trim() != currentProfilePicture;

    if (!hasChanges) {
      _showSnackBar('No changes to update.', Colors.orange);
      return;
    }

    final profilePicture = _profileImagePath.trim() != currentProfilePicture
        ? _profileImagePath
        : null;

    if (!mounted) return;

    setState(() {});

    await _controller.updateProfile(
      fullname: fullname,
      username: username,
      bio: bio,
      profile_picture: profilePicture,
    );

    if (!mounted) return;

    if (_controller.errorMessage == null &&
        _controller.profileResponse != null) {
      _populateFormFields();
      Navigator.of(context).pop(_controller.profileResponse);
      return;
    }

    if (_controller.errorMessage != null) {
      if (mounted) _showSnackBar(_controller.errorMessage!, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A2C8F),
      body: Column(
        children: [
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
                          height: 60,
                          width: 50,
                          child: Center(
                            child: SizedBox(
                              height: 30,
                              width: 30,
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
                          ? 'Hey, ${_controller.fullName}'
                          : 'Hey, User',
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

    if (_controller.errorMessage != null &&
        _controller.profileResponse == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${_controller.errorMessage}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
