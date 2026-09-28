import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/constants/api_constants.dart';

class ShareSocialButtons extends StatelessWidget {
  final String postId;

  const ShareSocialButtons({super.key, required this.postId});

  String get _postLink => '${ApiConstants.baseUrl}${ApiConstants.post(postId)}';

  Future<void> _onSocialButtonTap(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Check this out on Gruve! $_postLink',
        subject: 'Gruve',
      ),
    );
  }

  Future<void> _onCopyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _postLink));
    if (!context.mounted) return;
    _showTopToast(context, 'Link copied to clipboard!');
  }

  void _showTopToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 20,
        right: 20,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 700), entry.remove);
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

class _SocialButton extends StatefulWidget {
  final String iconPath;
  final Future<void> Function() onTap;

  const _SocialButton({required this.iconPath, required this.onTap});

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;

    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics unavailable on this device — non-critical.
    }

    setState(() => _isLoading = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isLoading ? null : _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: 45,
            width: 45,
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Image.asset(widget.iconPath, height: 45, width: 45),
          ),
        ),
      ),
    );
  }
}
