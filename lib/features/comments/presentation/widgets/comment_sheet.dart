import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/comments/domain/entities/comment_model.dart';
import 'package:gruve_app/features/comments/data/datasource/comment_service.dart';
import 'package:gruve_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:gruve_app/features/comments/presentation/widgets/shimmer/comment_shimmer.dart';
import 'package:gruve_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:gruve_app/shared/widgets/optimized/optimized_image.dart';

class CommentSheet extends ConsumerStatefulWidget {
  final String postId;
  final VoidCallback? onCommentAdded;
  final bool isEmbedded;
  final VoidCallback? onClose;

  const CommentSheet({
    super.key,
    required this.postId,
    this.onCommentAdded,
    this.isEmbedded = false,
    this.onClose,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  final CommentService _commentService = CommentService();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  Future<void>? _fetchInFlight;

  Comment? _replyingTo;
  String? _replyRootId;
  final Set<String> _expandedReplies = {};
  final Set<String> _likeInFlight = {};

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(_onFocusChange);
    _fetchComments();
  }

  void _onFocusChange() {
    if (_commentFocusNode.hasFocus && _replyingTo == null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _replyingTo == null) _scrollToBottom();
      });
    }
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
          duration: const Duration(milliseconds: 250),
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

  void _startReply(Comment target, {required String rootId}) {
    setState(() {
      _replyingTo = target;
      _replyRootId = rootId;
      _commentController.text = '@${target.user.username} ';
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyRootId = null;
      _commentController.clear();
    });
  }

  Future<void> _openProfile(CommentUser user) async {
    if (user.id.isEmpty) return;

    bool isOwnProfile =
        AuthStateManager().currentUserId?.trim() == user.id.trim();
    if (!isOwnProfile) {
      final resolution = await ProfileIdentityService.instance
          .resolveProfileIdentity(user.id);
      isOwnProfile = resolution.isOwnProfile;
    }

    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => isOwnProfile
            ? const ProfileScreen()
            : UserProfileScreen(
                profileUserId: user.id,
                userName: user.username,
                profileImageUrl: user.profilePicture,
              ),
      ),
    );
  }

  List<Comment> _mapComments(
    List<Comment> comments,
    String targetId,
    Comment Function(Comment) update,
  ) {
    return comments.map((c) {
      if (c.id == targetId) return update(c);
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _mapComments(c.replies, targetId, update));
      }
      return c;
    }).toList();
  }

  void _updateComment(String id, Comment Function(Comment) update) {
    setState(() => _comments = _mapComments(_comments, id, update));
  }

  int get _totalCommentCount =>
      _comments.length + _comments.fold<int>(0, (sum, c) => sum + c.replyCount);

  Future<void> _toggleLike(Comment comment) async {
    if (_likeInFlight.contains(comment.id)) return;
    _likeInFlight.add(comment.id);

    final wasLiked = comment.isLiked;
    final previousCount = comment.likeCount;
    final nextLiked = !wasLiked;
    final nextCount = previousCount + (nextLiked ? 1 : -1);

    _updateComment(
      comment.id,
      (c) => c.copyWith(isLiked: nextLiked, likeCount: nextCount),
    );

    CommentLikeResult? result;
    try {
      result = await _commentService.toggleCommentLike(comment.id);
    } catch (_) {
      result = null;
    }

    if (!mounted) return;

    if (result != null) {
      _updateComment(
        comment.id,
        (c) =>
            c.copyWith(isLiked: result!.isLiked, likeCount: result.likeCount),
      );
    } else {
      _updateComment(
        comment.id,
        (c) => c.copyWith(isLiked: wasLiked, likeCount: previousCount),
      );
    }

    _likeInFlight.remove(comment.id);
  }

  void _applyNewReply(String rootId, Comment reply) {
    final index = _comments.indexWhere((c) => c.id == rootId);
    if (index == -1) return;
    final root = _comments[index];
    final updatedRoot = root.copyWith(
      replyCount: root.replyCount + 1,
      replies: [...root.replies, reply],
    );
    setState(() {
      _comments = [
        ..._comments.sublist(0, index),
        updatedRoot,
        ..._comments.sublist(index + 1),
      ];
      _expandedReplies.add(rootId);
    });
  }

  Future<void> _submitComment() async {
    if (_isSending) {
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty || text.length > 5000) {
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

    FocusScope.of(context).unfocus();
    final replyRootId = _replyRootId;
    setState(() => _isSending = true);

    Comment? newComment;
    try {
      newComment = await _commentService
          .addComment(postId, text, parentCommentId: replyRootId)
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
      _commentController.clear();
      _replyingTo = null;
      _replyRootId = null;
      if (replyRootId != null) {
        _applyNewReply(replyRootId, savedComment);
        setState(() => _isSending = false);
      } else {
        setState(() {
          _comments = [..._comments, savedComment];
          _isSending = false;
        });
        _scrollToBottom();
      }
      widget.onCommentAdded?.call();
      unawaited(_syncCommentsAfterSend(postId));
      return;
    }

    setState(() {
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
    _commentFocusNode.removeListener(_onFocusChange);
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  static const List<String> _quickEmojis = [
    '❤️',
    '🙌',
    '🔥',
    '👏',
    '😢',
    '😍',
    '😮',
    '😂',
  ];

  void _insertEmoji(String emoji) {
    HapticFeedback.lightImpact();
    final text = _commentController.text;
    final selection = _commentController.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      _commentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + emoji.length),
      );
    } else {
      _commentController.text = '$text$emoji';
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserNotifierProvider);
    final userAvatarUrl = currentUser.profileImageUrl;
    final username = (currentUser.username != null && currentUser.username!.isNotEmpty)
        ? currentUser.username!
        : 'You';

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = keyboardInset > 0
        ? 8.0
        : (bottomInset > 0 ? bottomInset + 12.0 : 16.0);

    return Container(
      height: widget.isEmbedded ? null : MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.softPurple, AppColors.sheetDark],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          // Drag handle
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 6.0,
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
                  _totalCommentCount.toString(),
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return CommentTile(
                        key: ValueKey(comment.id),
                        comment: comment,
                        rootId: comment.id,
                        isExpanded: _expandedReplies.contains(comment.id),
                        onOpenProfile: _openProfile,
                        onToggleLike: _toggleLike,
                        onReply: (target, rootId) =>
                            _startReply(target, rootId: rootId),
                        onToggleReplies: () {
                          setState(() {
                            if (_expandedReplies.contains(comment.id)) {
                              _expandedReplies.remove(comment.id);
                            } else {
                              _expandedReplies.add(comment.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          if (_replyingTo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to @${_replyingTo!.user.username}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Quick Emoji Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _quickEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () => _insertEmoji(emoji),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Input Row
          Container(
            margin: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: bottomPadding,
              top: 4,
            ),
            child: Row(
              children: [
                OptimizedAvatar(
                  imageUrl: userAvatarUrl,
                  name: username,
                  radius: 18,
                  fallback: Image.asset(AppAssets.user, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 57, 6, 79),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color.fromARGB(80, 240, 58, 250),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'What do you think of this?',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _commentController,
                  builder: (context, val, _) {
                    final hasText = val.text.trim().isNotEmpty;
                    return SizedBox(
                      width: 38,
                      height: 38,
                      child: InkWell(
                        onTap: (_isSending || !hasText) ? null : _submitComment,
                        borderRadius: BorderRadius.circular(19),
                        child: Center(
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.loaderDark,
                                  ),
                                )
                              : Image.asset(
                                  AppAssets.sendbutton,
                                  height: 30,
                                  width: 30,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
