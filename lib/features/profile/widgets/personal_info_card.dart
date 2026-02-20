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

  const PersonalInfoCard({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.usernameController,
    required this.genderController,
    required this.bioController,
    required this.onSave,
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

              const SizedBox(height: 20),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 Header with edit icon
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

  /// 🔥 Field (Editable by default)
  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isBio = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: isBio ? 3 : 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
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
