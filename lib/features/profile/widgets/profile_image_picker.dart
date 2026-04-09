import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatefulWidget {
  final String currentImagePath;
  final Function(String) onImageChanged;
  final double radius;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerBottomSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.radius * 2 + 12, // ring padding
        height: widget.radius * 2 + 12,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Outer dark glow ──
            Center(
              child: Container(
                width: widget.radius * 2 + 12,
                height: widget.radius * 2 + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A0A2E).withValues(alpha: 0.9),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // ── Neon gradient ring ──
            Center(
              child: Container(
                width: widget.radius * 2 + 10,
                height: widget.radius * 2 + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFF00E5FF), // cyan
                      Color(0xFFD500F9), // purple
                      Color(0xFFFF4081), // pink
                      Color(0xFF00E5FF), // back to cyan
                    ],
                  ),
                ),
              ),
            ),

            // ── Profile image ──
            Center(
              child: Container(
                width: widget.radius * 2 + 4,
                height: widget.radius * 2 + 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0D0118), // dark gap between ring & image
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(child: _buildImage()),
                ),
              ),
            ),

            // ── Edit pencil button ──
            if (widget.showEditButton)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFF1A0A2E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.currentImagePath.isEmpty) {
      return Container(
        color: const Color(0xFF2D1150),
        child: const Icon(Icons.person, size: 60, color: Colors.white38),
      );
    }
    if (widget.currentImagePath.startsWith('http')) {
      return Image.network(
        widget.currentImagePath,
        width: widget.radius * 2,
        height: widget.radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF2D1150),
            child: const Icon(Icons.error, size: 40, color: Colors.white38),
          );
        },
      );
    }
    if (widget.currentImagePath.startsWith('assets')) {
      return Image.asset(
        widget.currentImagePath,
        width: widget.radius * 2,
        height: widget.radius * 2,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(widget.currentImagePath),
      width: widget.radius * 2,
      height: widget.radius * 2,
      fit: BoxFit.cover,
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET — dark purple theme
// ─────────────────────────────────────────────
class _PickerBottomSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PickerBottomSheet({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A0A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Change Profile Photo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OptionTile(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: onCamera,
              ),
              _OptionTile(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: onGallery,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9544A7), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9544A7).withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFB86AD0)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
