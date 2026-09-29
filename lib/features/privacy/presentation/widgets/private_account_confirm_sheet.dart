import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

/// Instagram-style confirmation sheet shown before switching an account
/// to private. Returns `true` only when the user explicitly confirms.
class PrivateAccountConfirmSheet extends StatelessWidget {
  const PrivateAccountConfirmSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const PrivateAccountConfirmSheet(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.65,
        maxWidth: 480,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deepPlum, Color(0xFF1B0A20)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, context.rh(10), 20, context.rh(14)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              SizedBox(height: context.rh(16)),

              Text(
                'Switch to private account?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.rf(18),
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: context.rh(16)),

              const _InfoRow(
                icon: Icons.smart_display_outlined,
                text:
                    'Only your approved followers can see your photos and videos.',
              ),
              SizedBox(height: context.rh(12)),
              const _InfoRow(
                icon: Icons.alternate_email_rounded,
                text:
                    'This won\'t change who can message, tag or mention you, but you won\'t be able to tag people who don\'t follow you.',
              ),
              SizedBox(height: context.rh(12)),
              const _InfoRow(
                icon: Icons.repeat_rounded,
                text:
                    'Previously shared content and follower visibility will be affected according to private account rules.',
              ),

              SizedBox(height: context.rh(18)),

              // Primary action
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => Navigator.of(context).pop(true),
                  child: Ink(
                    width: double.infinity,
                    height: context.rh(48),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF72008D), Color(0xFFFE24E0)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFE24E0,
                          ).withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Switch to private',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rf(15),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: context.rh(8)),

              // Secondary action
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => Navigator.of(context).pop(false),
                  child: Ink(
                    width: double.infinity,
                    height: context.rh(48),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rf(15),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.rw(38),
          height: context.rw(38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF56206B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white70,
                fontSize: context.rf(13),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
