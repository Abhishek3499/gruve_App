import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';

/// Widget for picking and displaying profile image with camera/gallery options
class ProfileImagePicker extends StatefulWidget {
  /// Current image path (asset or network)
  final String currentImagePath;

  /// Callback when image is changed/selected
  final Function(String) onImageChanged;

  /// Radius of the profile avatar
  final double radius;

  /// Whether to show edit button
  final bool showEditButton;

  const ProfileImagePicker({
    super.key,
    required this.currentImagePath,
    required this.onImageChanged,
    this.radius = 55,
    this.showEditButton = true,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();

  /// Picks image from specified source (camera/gallery)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onImageChanged(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  /// Shows bottom sheet for image source selection
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceBottomSheet(),
    );
  }

  /// Shows error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  /// Builds the image source selection bottom sheet
  Widget _buildImageSourceBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: 20),
          _buildBottomSheetTitle(),
          const SizedBox(height: 20),
          _buildImageSourceOptions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds the drag handle for bottom sheet
  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Builds the bottom sheet title
  Widget _buildBottomSheetTitle() {
    return const Text(
      'Change Profile Photo',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Builds camera and gallery options
  Widget _buildImageSourceOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildImageSourceOption(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          },
        ),
        _buildImageSourceOption(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  /// Builds individual image source option
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Color(0xFFFFFFFF)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the profile image with edit button overlay
  Widget _buildProfileImage() {
    return Stack(
      children: [
        // Profile Image
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withOpacity(0.6),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),

          child: CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: widget.currentImagePath.startsWith('assets')
                ? AssetImage(widget.currentImagePath)
                : null,
            child: _buildProfileImageChild(),
          ),
        ),

        // Edit Button
        if (widget.showEditButton)
          Positioned(bottom: 0, right: 0, child: _buildEditButton()),
      ],
    );
  }

  /// Builds the child for CircleAvatar (network image or default icon)
  Widget? _buildProfileImageChild() {
    if (widget.currentImagePath.startsWith('assets')) {
      return null; // Using backgroundImage for assets
    }

    if (widget.currentImagePath.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.currentImagePath,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }

    return _buildDefaultAvatar();
  }

  /// Builds default avatar icon
  Widget _buildDefaultAvatar() {
    return const Icon(Icons.person, size: 60, color: Colors.grey);
  }

  /// Builds the edit button overlay
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.edit, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: _buildProfileImage());
  }
}
