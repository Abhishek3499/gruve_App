import 'package:flutter/material.dart';

import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/shared/widgets/shimmer/app_shimmer.dart';
import 'package:gruve_app/features/auth/presentation/controller/edit_profile_controller.dart';
import 'package:gruve_app/features/account/domain/entities/profile_model.dart';
import 'package:gruve_app/features/profile/presentation/widgets/personal_info_card.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_image_picker.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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

  final ScrollController _scrollController = ScrollController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();

  bool _wasKeyboardOpen = false;
  String _profileImagePath = AppAssets.profile;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController();
    _initializeControllers();
    _fetchProfileData();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _nameFocusNode.addListener(_onFocusChange);
    _usernameFocusNode.addListener(_onFocusChange);
    _bioFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (_nameFocusNode.hasFocus) {
      _scrollToOffset(0);
    } else if (_usernameFocusNode.hasFocus) {
      _scrollToOffset(120);
    }
  }

  void _scrollToOffset(double offset) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToFocusedField() {
    if (_nameFocusNode.hasFocus) {
      _scrollToOffset(0);
    } else if (_usernameFocusNode.hasFocus) {
      _scrollToOffset(120);
    }
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

    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _bioFocusNode.dispose();
    _scrollController.dispose();
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
    FocusScope.of(context).unfocus();
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
      _showSnackBar('Profile updated successfully', Colors.green);
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
      backgroundColor: const Color(0xFF1B182D),
      body: Column(
        children: [
          Container(
            height: context.rh(190),
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
                    child: BackButton(
                      color: Colors.white,
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isKeyboardOpen =
                    MediaQuery.of(context).viewInsets.bottom > 0;

                if (_wasKeyboardOpen != isKeyboardOpen) {
                  _wasKeyboardOpen = isKeyboardOpen;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (isKeyboardOpen) {
                      _scrollToFocusedField();
                    } else {
                      _scrollToOffset(0);
                    }
                  });
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: isKeyboardOpen
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // A top purple block extending far above to cover overscroll stretch
                        Positioned(
                          top: -500,
                          left: 0,
                          right: 0,
                          height: 620, // 500px buffer + 120px normal height
                          child: Container(color: const Color(0xFF7A2C8F)),
                        ),
                        // The bottom body background
                        Positioned.fill(
                          top: 120,
                          child: Container(color: const Color(0xFF1B182D)),
                        ),
                        // The dark form container
                        Container(
                          margin: EdgeInsets.only(top: context.rh(60)),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B182D),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.elliptical(60, 50),
                              topRight: Radius.elliptical(60, 50),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 80,
                              left: 20,
                              right: 20,
                              bottom: isKeyboardOpen ? 10 : 60,
                            ),
                            child: _buildContent(),
                          ),
                        ),
                        // The avatar positioned at the top of the container
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _controller.isLoading
                                ? const AppShimmer(
                                    child: ShimmerCircle(radius: 61),
                                  )
                                : ProfileImagePicker(
                                    currentImagePath: _profileImagePath,
                                    onImageChanged: _onImageChanged,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading) {
      return const _EditProfileFormShimmer();
    }

    if (_controller.errorMessage != null &&
        _controller.profileResponse == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: context.rw(64), color: Colors.red),
            SizedBox(height: context.rh(16)),
            Text(
              'Error: ${_controller.errorMessage}',
              style: TextStyle(color: Colors.white, fontSize: context.rf(16)),
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
      );
    }

    return PersonalInfoCard(
      nameController: _nameController,
      phoneController: _phoneController,
      emailController: _emailController,
      usernameController: _usernameController,
      genderController: _genderController,
      bioController: _bioController,
      nameFocusNode: _nameFocusNode,
      usernameFocusNode: _usernameFocusNode,
      bioFocusNode: _bioFocusNode,
      onSave: _saveProfile,
      showEmail: _controller.showEmail,
      showPhone: _controller.showPhone,
      isUpdating: _controller.isUpdating,
    );
  }
}

class _EditProfileFormShimmer extends StatelessWidget {
  const _EditProfileFormShimmer();

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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 112, height: 18, borderRadius: 8),
                    ShimmerBox(width: 22, height: 22, borderRadius: 6),
                  ],
                ),
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
                const ShimmerBox(
                  width: double.infinity,
                  height: 48,
                  borderRadius: 30,
                ),
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
