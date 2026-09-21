import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/shared/widgets/get_started_button.dart';
import 'package:gruve_app/features/auth/presentation/widgets/inputs/neon_text_field.dart';
import 'package:gruve_app/shared/widgets/video_background.dart';
import 'package:gruve_app/features/auth/presentation/notifiers/complete_profile_notifier.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/features/home/presentation/screens/home_screen.dart';
import 'package:gruve_app/core/services/image_picker_service.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final GetStartedButtonController _completeButtonController =
      GetStartedButtonController();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();

  bool _usernameTouched = false;
  bool _profileImageTouched = false;
  String? _profileImageError;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(completeProfileNotifierProvider.notifier).reset();
      }
    });

    _usernameController.addListener(() {
      final error = SignupValidator.validateUsernameRealTime(
        _usernameController.text,
      );
      if (mounted) {
        setState(() {
          _usernameError = error;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateCompleteProfile() {
    if (mounted) {
      setState(() {
        _usernameTouched = true;
        _profileImageTouched = true;
      });
    }

    final selectedImage = ref
        .read(completeProfileNotifierProvider)
        .selectedImage;
    final username = _usernameController.text.trim();
    final usernameError = SignupValidator.validateUsernameRealTime(username);

    final profileImageError =
        selectedImage == null || selectedImage.path.trim().isEmpty
        ? 'Please add a profile photo to continue'
        : null;

    if (mounted) {
      setState(() {
        _profileImageError = profileImageError;
        _usernameError = usernameError;
      });
    }

    if (profileImageError != null) {
      _showSnackBar(profileImageError);
      return false;
    }

    if (usernameError != null) {
      _showSnackBar(
        username.isEmpty ? 'Please enter a username' : usernameError,
      );
      return false;
    }

    return true;
  }

  Future<void> _pickProfileImage() async {
    ImagePickerService.showImagePickerBottomSheet(
      context,
      onImageSelected: (image) async {
        if (image.path.trim().isEmpty) {
          if (!mounted) return;
          _showSnackBar('Please choose a valid profile photo');
          return;
        }

        final bytes = await image.readAsBytes();
        if (!mounted) return;

        if (bytes.isEmpty) {
          _showSnackBar(
            'Selected profile photo is empty. Please choose another image',
          );
          return;
        }

        ref
            .read(completeProfileNotifierProvider.notifier)
            .setProfileImage(image, bytes);
        setState(() => _profileImageError = null);
      },
    );
  }

  Future<bool> _completeProfile() async {
    FocusScope.of(context).unfocus();

    if (!_validateCompleteProfile()) return false;

    final completeProfileNotifier = ref.read(
      completeProfileNotifierProvider.notifier,
    );
    if (ref.read(completeProfileNotifierProvider).isLoading) return false;
    final selectedImage = ref
        .read(completeProfileNotifierProvider)
        .selectedImage;
    final username = _usernameController.text.trim();
    final file = selectedImage?.path;

    final result = await completeProfileNotifier.completeProfile(
      username: username,
      file: file,
      image: selectedImage,
    );

    if (!mounted) return false;

    if (!result.isSuccess) {
      _showSnackBar(
        result.errorMessage ?? 'Profile could not be saved. Please try again.',
      );
      return false;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final completeProfileState = ref.watch(completeProfileNotifierProvider);
    final selectedImage = completeProfileState.selectedImage;
    final selectedImageBytes = completeProfileState.selectedImageBytes;
    final isLoading = completeProfileState.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
              child: Column(
                children: [
                  SizedBox(height: context.rh(120)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: context.rf(22),
                          fontWeight: FontWeight.w500,
                          fontFamily: AppAssets.syncopateFont,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(text: 'Complete '),
                          TextSpan(
                            text: 'Profile',
                            style: TextStyle(color: AppColors.lavenderPurple),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.rh(20)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lorem Ipsum is simply dummy text of the\nprinting and typesetting industry',

                      textAlign: TextAlign.left,

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: context.rf(14),

                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: context.rh(40)),
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: context.rw(60),
                            backgroundColor: Colors.purple,
                            backgroundImage: selectedImageBytes != null
                                ? MemoryImage(selectedImageBytes)
                                : null,
                            child: selectedImage == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  )
                                : null,
                          ),

                          Positioned(
                            right: 5,
                            bottom: 17,
                            child: Container(
                              height: context.rh(26),
                              width: context.rw(26),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFB026FF),
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppAssets.editbutton,
                                  height: context.rh(15),
                                  width: context.rw(15),
                                  color: Colors.white,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child:
                        (_profileImageTouched ? _profileImageError : null) !=
                            null
                        ? Padding(
                            padding: EdgeInsets.only(top: context.rh(10)),
                            child: Text(
                              _profileImageError!,
                              style: TextStyle(
                                color: const Color(0xFFFF6B6B),
                                fontSize: context.rf(11),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(height: context.rh(40)),
                  NeonTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    hintText: 'Enter your username',
                    prefixIcon: AppAssets.user2,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _completeButtonController.submit(),
                    errorText: _usernameTouched ? _usernameError : null,
                  ),
                  SizedBox(height: context.rh(40)),
                  GetStartedButton(
                    controller: _completeButtonController,
                    text: 'Complete',
                    isLoading: isLoading,
                    onComplete: _completeProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
