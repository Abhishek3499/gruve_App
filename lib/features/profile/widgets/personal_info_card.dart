import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

/// Personal information card with editable profile fields
class PersonalInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController genderController;
  final TextEditingController bioController;
  final VoidCallback onSave;
  final bool showEditIcon;
  final bool showUpdateButton;
  final bool isReadOnly;

  const PersonalInfoCard({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.usernameController,
    required this.genderController,
    required this.bioController,
    required this.onSave,
    this.showEditIcon = true,
    this.showUpdateButton = true,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,

        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF9485EA), width: 0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),

              _buildField("Name", nameController),
              _divider(),

              _buildField("Phone", phoneController),
              _divider(),

              _buildField("Email", emailController),
              _divider(),

              _buildField("Username", usernameController),
              _divider(),

              _buildField("Gender", genderController),
              _divider(),

              _buildField("Bio", bioController, isBio: true),

              // Show update button only if showUpdateButton is true
              if (showUpdateButton) ...[
                const SizedBox(height: 20),
                _buildUpdateButton(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 Header with conditional edit icon
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Personal Info",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Show edit icon only if showEditIcon is true
        if (showEditIcon)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Image.asset(AppAssets.editpro, width: 22, height: 22),
          ),
      ],
    );
  }

  /// 🔥 Field (Read-only or Editable)
  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isBio = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !isReadOnly, // ✅ Read-only mode
          readOnly: isReadOnly, // ✅ Read-only mode
          maxLines: isBio ? 3 : 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFB5179E), Color(0xFF7209B7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onSave,
          child: const Center(
            child: Text(
              "Update",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
