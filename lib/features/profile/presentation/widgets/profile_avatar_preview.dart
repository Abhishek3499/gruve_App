import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';

/// Instagram-style avatar preview: long-pressing the profile photo pops this
/// up as an enlarged, centered image over a dimmed backdrop with an
/// "Edit Picture" action underneath. Tapping the backdrop dismisses it.
Future<void> showProfileAvatarPreview(
  BuildContext context, {
  required String profileImage,
  VoidCallback? onEditPicture,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Profile photo preview',
    barrierColor: Colors.black.withValues(alpha: 0.88),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ProfileAvatarPreview(
        profileImage: profileImage,
        onEditPicture: onEditPicture,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ProfileAvatarPreview extends StatelessWidget {
  final String profileImage;
  final VoidCallback? onEditPicture;

  const _ProfileAvatarPreview({required this.profileImage, this.onEditPicture});

  ImageProvider get _imageProvider {
    if (profileImage.startsWith('http')) return NetworkImage(profileImage);
    if (profileImage.startsWith('assets')) return AssetImage(profileImage);
    return const AssetImage(AppAssets.profile);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.62;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: GestureDetector(
              // Absorb taps on the content so they don't fall through to the
              // backdrop's dismiss handler.
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: _imageProvider,
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (onEditPicture != null) ...[
                    const SizedBox(height: 28),
                    _EditPictureButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        onEditPicture!();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditPictureButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditPictureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B2FC9), Color(0xFF6B1D9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFD946EF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B2FC9).withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Edit Picture',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
