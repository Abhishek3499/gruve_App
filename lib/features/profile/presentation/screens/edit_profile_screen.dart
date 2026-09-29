import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/shared/widgets/shimmer/app_shimmer.dart';
import 'package:gruve_app/features/profile/presentation/notifiers/edit_profile_notifier.dart';
import 'package:gruve_app/features/account/domain/entities/profile_model.dart';
import 'package:gruve_app/features/profile/presentation/widgets/personal_info_card.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_image_picker.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
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
  bool _isEditing = false;
  String _profileImagePath = AppAssets.profile;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupFocusListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfileData());
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
    await ref.read(editProfileNotifierProvider.notifier).fetchProfile();

    if (!mounted) return;

    if (ref.read(editProfileNotifierProvider).profileResponse != null) {
      _populateFormFields();
    }
  }

  void _populateFormFields() {
    final state = ref.read(editProfileNotifierProvider);
    if (state.profileResponse == null) return;

    _nameController.text = state.fullName;
    _usernameController.text = state.username;
    _emailController.text = state.email;
    _phoneController.text = state.phone;
    _genderController.text = state.gender;
    _bioController.text = state.bio;
    setState(() => _profileImagePath = state.currentProfilePicture);
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
    final notifier = ref.read(editProfileNotifierProvider.notifier);
    final currentState = ref.read(editProfileNotifierProvider);

    final fullname = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim().isEmpty
        ? null
        : _bioController.text.trim();

    final validationError = notifier.validateForm(
      fullName: fullname,
      username: username,
      bio: bio,
    );

    if (validationError != null) {
      _showSnackBar(validationError, Colors.red);
      return;
    }

    final currentFullName = currentState.fullName.trim();
    final currentUsername = currentState.username.trim();
    final currentBio = currentState.bio.trim();
    final currentProfilePicture = currentState.currentProfilePicture.trim();
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

    await notifier.updateProfile(
      fullname: fullname,
      username: username,
      bio: bio,
      profilePicture: profilePicture,
    );

    if (!mounted) return;

    final updatedState = ref.read(editProfileNotifierProvider);
    if (updatedState.errorMessage == null &&
        updatedState.profileResponse != null) {
      _populateFormFields();
      _showSnackBar('Profile updated successfully', Colors.green);
      Navigator.of(context).pop(updatedState.profileResponse);
      return;
    }

    if (updatedState.errorMessage != null) {
      _showSnackBar(updatedState.errorMessage!, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF7A2C8F),
      body: Column(
        children: [
          Container(
            height: context.rh(190),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.deepPlum, Color(0xFF7A2C8F)],
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
                      state.profileResponse != null
                          ? 'Hey, ${state.fullName}'
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Scrollable dark card — avatar below stays fixed, outside
                // this scroll view, so it never gets clipped while scrolling.
                Positioned.fill(
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
                          child: Container(
                            margin: EdgeInsets.only(top: context.rh(4)),
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
                                top: context.rh(80),
                                left: context.rw(20),
                                right: context.rw(20),
                                bottom: isKeyboardOpen ? 10 : 20,
                              ),
                              child: _buildContent(state),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Avatar — fixed above the card boundary, unaffected by scroll.
                Positioned(
                  top: -70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: state.isLoading
                        ? const AppShimmer(child: ShimmerCircle(radius: 61))
                        : ProfileImagePicker(
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

  Widget _buildContent(EditProfileState state) {
    if (state.isLoading) {
      return const _EditProfileFormShimmer();
    }

    if (state.errorMessage != null && state.profileResponse == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: context.rw(64), color: Colors.red),
            SizedBox(height: context.rh(16)),
            Text(
              'Error: ${state.errorMessage}',
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
      onEditTap: () => setState(() => _isEditing = true),
      showEditIcon: true,
      isReadOnly: !_isEditing,
      showEmail: state.showEmail,
      showPhone: state.showPhone,
      isUpdating: state.isUpdating,
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
            padding: EdgeInsets.symmetric(
              horizontal: context.rw(10),
              vertical: context.rh(5),
            ),
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
