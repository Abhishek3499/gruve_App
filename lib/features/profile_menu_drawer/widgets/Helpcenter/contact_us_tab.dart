import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ContactUsTab extends StatelessWidget {
  const ContactUsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF7D2D90),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(17),
          children: const [
            _ContactSupportButton(
              imagePath: AppAssets.contact,
              title: 'Contact us',
            ),
            SizedBox(height: 23),
            _ContactSupportButton(
              imagePath: AppAssets.whatsapp,
              title: 'WhatsApp',
            ),
            SizedBox(height: 23),
            _ContactSupportButton(
              imagePath: AppAssets.instagram,
              title: 'Instagram',
            ),
            SizedBox(height: 23),
            _ContactSupportButton(
              imagePath: AppAssets.facebook,
              title: 'Facebook',
            ),
            SizedBox(height: 23),
            _ContactSupportButton(
              imagePath: AppAssets.twitter,
              title: 'Twitter',
            ),
            SizedBox(height: 23),
            _ContactSupportButton(
              imagePath: AppAssets.website,
              title: 'Website',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSupportButton extends StatelessWidget {
  final String imagePath;
  final String title;

  const _ContactSupportButton({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 85,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF8E3AA8),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
            color: Colors.white, // remove if original color chahiye
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
