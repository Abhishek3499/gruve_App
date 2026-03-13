import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ShareSocialButtons extends StatelessWidget {
  const ShareSocialButtons({super.key});

  void _onSocialButtonTap(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share via $platform'),
        backgroundColor: const Color(0xFF7A1FA2),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onCopyLink(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Color(0xFF7A1FA2),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SocialButton(
            iconPath: AppAssets.whatsapps,
            onTap: () => _onSocialButtonTap(context, 'WhatsApp'),
          ),

          _SocialButton(
            iconPath: AppAssets.instagram,
            onTap: () => _onSocialButtonTap(context, 'Instagram'),
          ),

          _SocialButton(
            iconPath: AppAssets.snapchats,
            onTap: () => _onSocialButtonTap(context, 'Snapchat'),
          ),

          _SocialButton(
            iconPath: AppAssets.copy,
            onTap: () => _onCopyLink(context),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;

  const _SocialButton({required this.iconPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(iconPath, height: 45, width: 45),
    );
  }
}
