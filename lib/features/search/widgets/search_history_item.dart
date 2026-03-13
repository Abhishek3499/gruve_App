import 'package:flutter/material.dart';
import '../models/search_history_model.dart';

class SearchHistoryItem extends StatelessWidget {
  final SearchHistoryModel historyItem;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const SearchHistoryItem({
    super.key,
    required this.historyItem,
    this.onTap,
    this.onRemove,
  });

  Widget _buildAvatar() {
    switch (historyItem.type) {
      case SearchType.user:
        return CircleAvatar(
          radius: 22,
          backgroundImage: historyItem.avatar != null
              ? NetworkImage(historyItem.avatar!)
              : null,
          backgroundColor: Colors.grey.shade300,
        );

      case SearchType.hashtag:
        return const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFF8E2DE2),
          child: Icon(Icons.tag, color: Colors.white),
        );

      case SearchType.music:
        return const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFF8E2DE2),
          child: Icon(Icons.music_note, color: Colors.white),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _buildAvatar(),

              const SizedBox(width: 12),

              /// Text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historyItem.query,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      historyItem.subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              /// Remove button
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, color: Colors.white54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
