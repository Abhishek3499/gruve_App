import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';

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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwnProfile) ...[
                    _buildActionTile(
                      icon: Icons.edit_outlined,
                      label: 'Edit Post',
                      onTap: () {
                        Navigator.pop(context);
                        debugPrint('📝 Edit post: ${post.id}');
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.delete_outline,
                      label: 'Delete Post',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(context, post);
                      },
                    ),
                    const Divider(color: Colors.white12, height: 16),
                  ],
                  _buildActionTile(
                    icon: Icons.share_outlined,
                    label: 'Share Post',
                    onTap: () {
                      Navigator.pop(context);
                      debugPrint('📤 Share post: ${post.id}');
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.link,
                    label: 'Copy Link',
                    onTap: () {
                      Navigator.pop(context);
                      debugPrint('🔗 Copy link: ${post.id}');
                    },
                  ),
                  if (!isOwnProfile) ...[
                    const Divider(color: Colors.white12, height: 16),
                    _buildActionTile(
                      icon: Icons.flag_outlined,
                      label: 'Report Post',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        debugPrint('🚩 Report post: ${post.id}');
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.block_outlined,
                      label: 'Block User',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        debugPrint('🚫 Block user: ${post.userId}');
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildActionTile(
                    icon: Icons.close,
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Post?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              debugPrint('🗑️ Deleted post: ${post.id}');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
