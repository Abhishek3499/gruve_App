import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_draft_model.dart';

class DraftTile extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DraftTile({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.onDelete,
  });

  String _getFormattedDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown date';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Edited on ${dateTime.day} $month at $hour:$minute $ampm';
  }

  String _getPrefText() {
    final parts = <String>[];
    if (draft.locationName != null && draft.locationName!.isNotEmpty) {
      parts.add(draft.locationName!);
    }
    parts.add(draft.audienceCloseFriends ? 'Close Friends' : 'Everyone');
    if (draft.scheduleReel) {
      parts.add('Scheduled');
    }
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail Image
          Container(
            width: 75,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (draft.mediaUrl != null && draft.mediaUrl!.isNotEmpty)
                  ? Image.network(
                      draft.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(AppAssets.draft, fit: BoxFit.cover);
                      },
                    )
                  : Image.asset(AppAssets.draft, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (draft.caption != null && draft.caption!.isNotEmpty)
                      ? draft.caption!
                      : 'Draft #${draft.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedDate(draft.updatedAt ?? draft.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPrefText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // Options Icon
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: const Color(0xFF1E092D),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              color: const Color(0xFF1E092D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              offset: const Offset(0, 40),
              onSelected: (result) {
                if (result == 'edit') {
                  onEdit();
                } else if (result == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Edit Draft', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
