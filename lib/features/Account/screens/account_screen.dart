import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/Account/widgets/account_body.dart';
import 'package:gruve_app/features/Account/widgets/account_header.dart';
import 'package:gruve_app/features/profile/models/profile_model.dart';
import 'package:gruve_app/features/auth/api/controllers/edit_profile_controller.dart';
import 'package:gruve_app/core/widgets/shimmer/app_shimmer.dart';
import '../../../../core/assets.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d('🔄 [AccountScreen] Fetching profile data...');
    await _controller.fetchProfile();

    if (!mounted) return;

    if (_controller.profileResponse != null) {
      _populateFormFields();
      AppLogger.d('✅ [AccountScreen] Profile data loaded successfully');
    } else {
      AppLogger.d('❌ [AccountScreen] Failed to load profile data');
      setState(() {});
    }
  }

  void _populateFormFields() {
    if (_controller.profileResponse == null) {
      AppLogger.d('⚠️ [AccountScreen] Profile response is null');
      return;
    }

    AppLogger.d('📝 [AccountScreen] Populating form fields with profile data');
    AppLogger.d('👤 Full Name: ${_controller.fullName}');
    AppLogger.d('📧 Email: ${_controller.email}');
    AppLogger.d('📱 Phone: ${_controller.phone}');
    AppLogger.d('👥 Username: ${_controller.username}');
    AppLogger.d('⚧️ Gender: ${_controller.gender}');
    AppLogger.d('📝 Bio: ${_controller.bio}');

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
      body: Column(
        children: [
          /// Header with dynamic fullName
          AccountHeader(
            fullName: _controller.fullName,
            isLoading: _controller.isLoading,
          ),

          /// Main Body
          Expanded(
            child: _controller.isLoading
                ? const _AccountBodyShimmer()
                : _controller.errorMessage != null &&
                      _controller.profileResponse == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: context.rw(64),
                          color: Colors.red,
                        ),
                        SizedBox(height: context.rh(16)),
                        Text(
                          'Error: ${_controller.errorMessage}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rf(16),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.rh(24)),
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
    );
  }
}

class _AccountBodyShimmer extends StatelessWidget {
  const _AccountBodyShimmer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: context.rh(4)),
          decoration: const BoxDecoration(
            color: Color(0xFF1B182D),
            borderRadius: BorderRadius.only(
              topLeft: Radius.elliptical(60, 50),
              topRight: Radius.elliptical(60, 50),
            ),
          ),
          padding: EdgeInsets.only(
            top: context.rh(80),
            left: context.rw(20),
            right: context.rw(20),
            bottom: context.rh(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _AccountInfoCardShimmer(),
              SizedBox(height: context.rh(20)),
              const _AccountFooterShimmer(),
            ],
          ),
        ),
        const Positioned(
          top: -70,
          left: 0,
          right: 0,
          child: Center(child: AppShimmer(child: ShimmerCircle(radius: 61))),
        ),
      ],
    );
  }
}

class _AccountInfoCardShimmer extends StatelessWidget {
  const _AccountInfoCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: context.rw(320),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF9485EA), width: 0.3),
        ),
        child: AppShimmer(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rw(10), vertical: context.rh(5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.rh(20)),
                const ShimmerBox(width: 112, height: 18, borderRadius: 8),
                SizedBox(height: context.rh(24)),
                _buildField(width: 168),
                _divider(),
                _buildField(width: 132),
                _divider(),
                _buildField(width: 210),
                _divider(),
                _buildField(width: 150),
                _divider(),
                _buildField(width: 92),
                _divider(),
                _buildField(width: double.infinity, isBio: true),
                SizedBox(height: context.rh(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildField({required double width, bool isBio = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBox(width: 72, height: 12, borderRadius: 6),
        const SizedBox(height: 8),
        ShimmerBox(width: width, height: isBio ? 58 : 16, borderRadius: 8),
      ],
    );
  }

  static Widget _divider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
    );
  }
}

class _AccountFooterShimmer extends StatelessWidget {
  const _AccountFooterShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          const ShimmerBox(width: 112, height: 14, borderRadius: 6),
          SizedBox(height: context.rh(8)),
          const ShimmerBox(width: 190, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}
