import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import '../../../../core/assets.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  final VoidCallback? onCommentAdded;

  const CommentSheet({super.key, required this.postId, this.onCommentAdded});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatCount(String count) {
    if (count.contains('k')) return count;

    final num = int.tryParse(count) ?? 0;

    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          /// ❌ API nahi hai → empty state
          const Expanded(
            child: Center(
              child: Text(
                "No comments yet",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          /// INPUT
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(26, 57, 6, 79),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color.fromARGB(51, 240, 58, 250),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Comment',
                      hintStyle: TextStyle(color: Colors.white, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: () async {
                    final text = _commentController.text.trim();

                    if (text.isEmpty) return;

                    await PostService().addComment(widget.postId, text);

                    print("💬 COMMENT ADDED: $text");

                    widget.onCommentAdded?.call();

                    _commentController.clear();

                    if (!mounted) return; // ✅ FIX

                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    AppAssets.sendbutton,
                    height: 32,
                    width: 32,
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
