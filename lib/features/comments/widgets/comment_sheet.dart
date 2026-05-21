import 'package:flutter/material.dart';
import '../../../../core/assets.dart';
import '../../../../core/widgets/optimized/optimized_image.dart';
import '../../comments/models/comment_model.dart';
import '../../comments/api/comment_service.dart';
import '../../../../core/widgets/shimmer/comment_shimmer.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  final VoidCallback? onCommentAdded;

  const CommentSheet({super.key, required this.postId, this.onCommentAdded});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CommentService _commentService = CommentService();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  Future<void>? _fetchInFlight;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    if (_fetchInFlight != null) return _fetchInFlight!;
    final future = _runFetchComments();
    _fetchInFlight = future;
    try {
      return await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _runFetchComments() async {
    setState(() => _isLoading = true);
    final comments = await _commentService.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Comments",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _comments.length.toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          Expanded(
            child: _isLoading
                ? const CommentShimmer(itemCount: 5)
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          "No comments yet. Be the first!",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentTile(_comments[index]);
                        },
                      ),
          ),

          Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(50, 57, 6, 79),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color.fromARGB(80, 240, 58, 250),
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
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) return;

                    _commentController.clear();
                    FocusScope.of(context).unfocus();
                    setState(() => _isSending = true);

                    // Optimistic insert
                    final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                    final optimistic = Comment(
                      id: optimisticId,
                      body: text,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      user: CommentUser(id: '', username: 'You', isSubscribed: false),
                    );
                    setState(() => _comments.add(optimistic));
                    _scrollToBottom();

                    final newComment = await _commentService.addComment(widget.postId, text);
                    CommentService.invalidatePost(widget.postId);

                    if (!mounted) return;
                    if (newComment != null) {
                      setState(() {
                        final idx = _comments.indexWhere((c) => c.id == optimisticId);
                        if (idx != -1) _comments[idx] = newComment;
                        _isSending = false;
                      });
                      widget.onCommentAdded?.call();
                    } else {
                      setState(() {
                        _comments.removeWhere((c) => c.id == optimisticId);
                        _isSending = false;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to post comment", style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: _isSending
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : Image.asset(
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

  Widget _buildCommentTile(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OptimizedAvatar(
            imageUrl: comment.user.profilePicture,
            name: comment.user.username,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      comment.user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (comment.updatedAt.isAfter(comment.createdAt.add(const Duration(seconds: 10)))) ...[
                  const SizedBox(height: 2),
                  const Text(
                    "Edited",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
