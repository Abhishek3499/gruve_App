import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/user_profile/utils/report_user_flow.dart';
import 'package:gruve_app/features/video_options/sheets/simple_report_sheet.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class PostActionSheet extends StatelessWidget {
  final Post post;
  final bool isOwnProfile;

  const PostActionSheet({
    super.key,
    required this.post,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.rh(12)),
              child: Container(
                width: context.rw(40),
                height: context.rh(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.rw(16),
                vertical: context.rh(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwnProfile) ...[
                    _buildActionTile(
                      context: context,
                      icon: Icons.delete_outline,
                      label: 'Delete Post',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context, 'delete');
                      },
                    ),
                  ],
                  if (!isOwnProfile) ...[
                    _buildActionTile(
                      context: context,
                      icon: Icons.flag_outlined,
                      label: 'Report Post',
                      color: Colors.orange,
                      onTap: () {
                        final userId = post.userId;
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        ReportUserFlow.showAndSubmit(
                          context: navigator.context,
                          userId: userId,
                          target: ReportSheetTarget.post,
                        );
                      },
                    ),
                    _buildActionTile(
                      context: context,
                      icon: Icons.block_outlined,
                      label: 'Block User',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        AppLogger.d('🚫 Block user: ${post.userId}');
                      },
                    ),
                  ],
                  SizedBox(height: context.rh(8)),
                  _buildActionTile(
                    context: context,
                    icon: Icons.close,
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rh(8)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.rw(16),
            vertical: context.rh(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: context.rw(22)),
              SizedBox(width: context.rw(16)),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: context.rf(16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
