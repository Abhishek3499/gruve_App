import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/comments/domain/entities/comment_model.dart';
import 'package:gruve_app/shared/widgets/optimized/optimized_image.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isReply;
  final String rootId;
  final bool isExpanded;
  final ValueChanged<CommentUser> onOpenProfile;
  final void Function(Comment comment, String rootId) onReply;
  final ValueChanged<Comment> onToggleLike;
  final VoidCallback? onToggleReplies;

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    required this.rootId,
    this.isExpanded = false,
    required this.onOpenProfile,
    required this.onReply,
    required this.onToggleLike,
    this.onToggleReplies,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 14.0 : 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onOpenProfile(comment.user),
            child: OptimizedAvatar(
              imageUrl: comment.user.profilePicture,
              name: comment.user.username,
              radius: isReply ? 13 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => onOpenProfile(comment.user),
                      child: Text(
                        comment.user.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isReply ? 12 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isReply ? 17 : 18,
                  ),
                ),
                if (comment.updatedAt.isAfter(
                  comment.createdAt.add(const Duration(seconds: 10)),
                )) ...[
                  const SizedBox(height: 2),
                  const Text(
                    "Edited",
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => onReply(comment, rootId),
                  child: const Text(
                    'Reply',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isReply && comment.replyCount > 0) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onToggleReplies,
                    child: Row(
                      children: [
                        Container(width: 20, height: 1, color: Colors.white38),
                        const SizedBox(width: 8),
                        Text(
                          isExpanded
                              ? 'Hide replies'
                              : 'View replies (${comment.replyCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 14),
                    ...comment.replies.map(
                      (reply) => CommentTile(
                        comment: reply,
                        isReply: true,
                        rootId: comment.id,
                        onOpenProfile: onOpenProfile,
                        onReply: onReply,
                        onToggleLike: onToggleLike,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggleLike(comment),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: isReply ? 17 : 18,
                    color: comment.isLiked ? AppColors.pink : Colors.white70,
                  ),
                  if (comment.likeCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${comment.likeCount}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
