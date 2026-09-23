import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/constants/api_constants.dart';

class ShareSocialButtons extends StatelessWidget {
  final String postId;

  const ShareSocialButtons({super.key, required this.postId});

  String get _postLink => '${ApiConstants.baseUrl}${ApiConstants.post(postId)}';

  void _onSocialButtonTap(BuildContext context) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check this out on Gruve! $_postLink',
        subject: 'Gruve',
      ),
    );
  }

  void _onCopyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _postLink));
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
            onTap: () => _onSocialButtonTap(context),
          ),

          _SocialButton(
            iconPath: AppAssets.social,
            onTap: () => _onSocialButtonTap(context),
          ),

          _SocialButton(
            iconPath: AppAssets.snapchats,
            onTap: () => _onSocialButtonTap(context),
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
