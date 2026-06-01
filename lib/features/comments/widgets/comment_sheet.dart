import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/assets.dart';
import '../../../../core/constants/app_colors.dart';
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
    final comments = await _commentService.getComments(
      widget.postId,
      forceRefresh: true,
    );
    if (mounted) {
      setState(() {
        _comments = List<Comment>.of(comments);
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

  Future<void> _syncCommentsAfterSend(String postId) async {
    try {
      final comments = await _commentService
          .getComments(postId, forceRefresh: true)
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;
      if (comments.isEmpty) {
        return;
      }

      setState(() => _comments = List<Comment>.of(comments));
      _scrollToBottom();
    } catch (e) {
      // Keep the optimistic comment visible if the background refresh fails.
    }
  }

  Future<void> _submitComment() async {
    if (_isSending) {
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final postId = widget.postId.trim();
    if (postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to post comment right now',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _commentController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Comment(
      id: optimisticId,
      body: text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      user: CommentUser(id: '', username: 'You', isSubscribed: false),
    );
    setState(() => _comments = [..._comments, optimistic]);
    _scrollToBottom();

    Comment? newComment;
    try {
      newComment = await _commentService
          .addComment(postId, text)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              return null;
            },
          );
    } catch (_) {
      newComment = null;
    }
    CommentService.invalidatePost(postId);

    if (!mounted) return;
    if (newComment != null) {
      final savedComment = newComment;
      setState(() {
        final idx = _comments.indexWhere((c) => c.id == optimisticId);
        if (idx != -1) _comments[idx] = savedComment;
        _isSending = false;
      });
      widget.onCommentAdded?.call();
      unawaited(_syncCommentsAfterSend(postId));
      return;
    }

    setState(() {
      _comments.removeWhere((c) => c.id == optimisticId);
      _isSending = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Failed to post comment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: InkWell(
                    onTap: _isSending ? null : _submitComment,
                    borderRadius: BorderRadius.circular(22),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.loaderDark,
                              ),
                            )
                          : Image.asset(
                              AppAssets.sendbutton,
                              height: 32,
                              width: 32,
                            ),
                    ),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
