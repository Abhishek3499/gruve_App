import 'package:flutter/material.dart';
import 'package:gruve_app/features/Account/widgets/account_body.dart';
import 'package:gruve_app/features/Account/widgets/account_header.dart';
import 'package:gruve_app/features/profile/models/profile_model.dart';
import 'package:gruve_app/screens/auth/api/controllers/edit_profile_controller.dart';
import '../../../../core/assets.dart';

/// Account Screen with professional widget separation
class AccountScreen extends StatefulWidget {
  final ProfileModel? initialProfile;

  const AccountScreen({super.key, this.initialProfile});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
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
    final profile = widget.initialProfile ?? _defaultProfile();

    _nameController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _emailController = TextEditingController(text: '');
    _usernameController = TextEditingController(text: '');
    _genderController = TextEditingController(text: '');
    _bioController = TextEditingController(text: '');
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

  Future<void> _fetchProfileData() async {
    debugPrint('🔄 [AccountScreen] Fetching profile data...');
    await _controller.fetchProfile();

    if (!mounted) return;

    if (_controller.profileResponse != null) {
      _populateFormFields();
      debugPrint('✅ [AccountScreen] Profile data loaded successfully');
    } else {
      debugPrint('❌ [AccountScreen] Failed to load profile data');
      setState(() {});
    }
  }

  void _populateFormFields() {
    if (_controller.profileResponse == null) {
      debugPrint('⚠️ [AccountScreen] Profile response is null');
      return;
    }

    debugPrint('📝 [AccountScreen] Populating form fields with profile data');
    debugPrint('👤 Full Name: ${_controller.fullName}');
    debugPrint('📧 Email: ${_controller.email}');
    debugPrint('📱 Phone: ${_controller.phone}');
    debugPrint('👥 Username: ${_controller.username}');
    debugPrint('⚧️ Gender: ${_controller.gender}');
    debugPrint('📝 Bio: ${_controller.bio}');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A2C8F),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              /// Header with dynamic fullName
              AccountHeader(
                fullName: _controller.fullName,
                isLoading: _controller.isLoading,
              ),

              /// Main Body
              Expanded(
                child:
                    _controller.errorMessage != null &&
                        _controller.profileResponse == null
                    ? Center(
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
                      )
                    : AccountBody(
                        nameController: _nameController,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        usernameController: _usernameController,
                        genderController: _genderController,
                        bioController: _bioController,
                        profileImagePath: _profileImagePath,
                      ),
              ),
            ],
          ),

          // Full-screen loading overlay (only blocks body, not header)
          if (_controller.isLoading)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Empty space for header (so back button is not blocked)
                        const SizedBox(height: 190),

                        // Loading indicator in body area
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Loading your profile...',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
