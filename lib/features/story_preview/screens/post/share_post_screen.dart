import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/story_preview/screens/audience/audience_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/more_option_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/tag_people_screen.dart';
import 'package:gruve_app/features/story_preview/providers/drafts_provider.dart';

import 'package:gruve_app/features/story_preview/api/post/menu_row.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SharePostScreen extends StatefulWidget {
  final String mediaPath;
  final List<ChatUser>? taggedUsers;

  /// When [SharePostScreen] was pushed from [PostPreviewScreen], pop that route
  /// after share so the user returns to the home feed (camera flow is already gone).
  /// When opened from a sheet or with PostPreview already popped, keep `false`.
  final bool popPostPreviewRouteAfterShare;
  final String? draftId;

  final String? initialCaption;
  final String? initialLocation;
  final bool? initialIsEveryone;
  final bool? initialIsCloseFriends;
  final bool? initialScheduleReel;
  final bool? initialUploadHighQuality;
  final bool? initialHideLikeCount;
  final bool? initialHideShareCount;

  const SharePostScreen({
    super.key,
    required this.mediaPath,
    this.taggedUsers,
    this.popPostPreviewRouteAfterShare = false,
    this.draftId,
    this.initialCaption,
    this.initialLocation,
    this.initialIsEveryone,
    this.initialIsCloseFriends,
    this.initialScheduleReel,
    this.initialUploadHighQuality,
    this.initialHideLikeCount,
    this.initialHideShareCount,
  });

  @override
  State<SharePostScreen> createState() => _SharePostScreenState();
}

class _SharePostScreenState extends State<SharePostScreen> {
  List<ChatUser> selectedUsers = [];
  List<ChatUser> taggedUsers = [];
  late TextEditingController captionController;
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isVideoInitialized = false;
  bool _isSharing = false;

  // Save Draft settings states
  late bool isEveryone;
  late bool isCloseFriends;
  late bool scheduleReel;
  late bool uploadHighQuality;
  late bool hideLikeCount;
  late bool hideShareCount;
  String? locationName;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d(
      "🎬 [SharePostScreen] initState - widget.draftId: '${widget.draftId}', initialCaption: '${widget.initialCaption}'",
    );
    captionController = TextEditingController(text: widget.initialCaption);
    isEveryone = widget.initialIsEveryone ?? true;
    isCloseFriends = widget.initialIsCloseFriends ?? false;
    scheduleReel = widget.initialScheduleReel ?? false;
    uploadHighQuality = widget.initialUploadHighQuality ?? false;
    hideLikeCount = widget.initialHideLikeCount ?? false;
    hideShareCount = widget.initialHideShareCount ?? false;
    locationName = widget.initialLocation;

    if (widget.taggedUsers != null) {
      taggedUsers = List.from(widget.taggedUsers!);
    }
    _initializeVideoPreview();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    captionController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPreview() async {
    _isVideo = _isVideoPath(widget.mediaPath);
    if (!_isVideo) return;

    try {
      _videoController = widget.mediaPath.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.mediaPath))
          : VideoPlayerController.file(File(widget.mediaPath));

      await _videoController!.initialize();
      await _videoController!.setLooping(false);

      if (!mounted) return;
      setState(() => _isVideoInitialized = true);
    } catch (e) {
      AppLogger.d('SharePostScreen video preview error: $e');
      if (!mounted) return;
      setState(() => _isVideoInitialized = false);
    }
  }

  bool _isVideoPath(String path) {
    final uri = Uri.tryParse(path);
    final cleanPath = uri?.path.toLowerCase() ?? path.toLowerCase();
    return cleanPath.endsWith('.mp4') ||
        cleanPath.endsWith('.mov') ||
        cleanPath.endsWith('.avi') ||
        cleanPath.endsWith('.mkv') ||
        cleanPath.endsWith('.webm');
  }

  void _showLocationDialog() {
    final locationController = TextEditingController(text: locationName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E092D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Location",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (locationName != null && locationName!.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          locationName = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter location name...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB86AD0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    locationName = locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 120, 2, 99),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  "Save Location",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleShare() async {
    if (_isSharing) return;

    final caption = captionController.text.trim();
    final mediaPath = widget.mediaPath;

    // Block submit if neither caption nor media provided
    if (caption.isEmpty && mediaPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Add a caption and/or a media file."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Block submit if more than 20 tagged users
    if (taggedUsers.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A post can have at most 20 tagged users."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSharing = true);

    AppLogger.d("🔥 SHARE CLICKED");

    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);

    final taggedUserIds = taggedUsers.map((u) => u.id).toList();

    PostShareFlowBridge.scheduleShareUploadAfterReturningHome(
      caption: caption,
      mediaPath: mediaPath,
      locationName: locationName,
      audienceEveryone: isEveryone,
      audienceCloseFriends: isCloseFriends,
      scheduleReel: scheduleReel,
      uploadHighQuality: uploadHighQuality,
      hideLikeCount: hideLikeCount,
      hideShareCount: hideShareCount,
      taggedUserIds: taggedUserIds,
      draftId: widget.draftId,
    );
  }

  void _handleSaveDraft() async {
    if (_isSavingDraft) return;

    final caption = captionController.text.trim();
    final mediaPath = widget.mediaPath;

    // Block submit if neither caption nor media provided
    if (caption.isEmpty && mediaPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Add a caption and/or a media file."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Block submit if more than 20 tagged users
    if (taggedUsers.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A post can have at most 20 tagged users."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingDraft = true);

    AppLogger.d(
      "💾 [SharePostScreen] _handleSaveDraft - widget.draftId is: '${widget.draftId}'",
    );

    final draftsProvider = context.read<DraftsProvider>();

    try {
      if (widget.draftId != null) {
        AppLogger.d(
          "💾 [SharePostScreen] _handleSaveDraft: Calling updateDraft with draftId: '${widget.draftId}'",
        );
        await draftsProvider.updateDraft(
          draftId: widget.draftId!,
          caption: caption,
          mediaPath: mediaPath,
          locationName: locationName ?? "",
          audienceEveryone: isEveryone,
          audienceCloseFriends: isCloseFriends,
          scheduleReel: scheduleReel,
          uploadHighQuality: uploadHighQuality,
          hideLikeCount: hideLikeCount,
          hideShareCount: hideShareCount,
        );
      } else {
        AppLogger.d(
          "💾 [SharePostScreen] _handleSaveDraft: Calling saveDraft (draftId is null)",
        );
        await draftsProvider.saveDraft(
          caption: caption,
          mediaPath: mediaPath,
          locationName: locationName,
          audienceEveryone: isEveryone,
          audienceCloseFriends: isCloseFriends,
          scheduleReel: scheduleReel,
          uploadHighQuality: uploadHighQuality,
          hideLikeCount: hideLikeCount,
          hideShareCount: hideShareCount,
        );
      }

      if (!mounted) return;

      // Navigate to profile tab smoothly
      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.isFirst);
      PostShareFlowBridge.onRequestShowProfileTab?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static const _backgroundGradient = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.8, -0.8),
      colors: [Color(0xFF2A0944), Color(0xFF0D0214)],
      radius: 1.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Debug logging
    AppLogger.d('SharePostScreen received mediaPath: ${widget.mediaPath}');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0214), // Dark purple background
      body: Container(
        decoration: _backgroundGradient,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: Image.asset(
                  AppAssets.back,
                  color: Colors.white,
                  height: 28,
                  width: 28,
                ),
                onPressed: () {
                  Navigator.pop(context, taggedUsers);
                },
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Media Preview Widget
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.80,
                          height: 300,

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: _buildMediaPreview(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Caption Area
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: captionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a caption...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Hashtag Chip (Reusable Component)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            avatar: const Text(
                              '#',
                              style: TextStyle(color: Colors.white60),
                            ),
                            label: const Text(
                              'Hashtags',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {},
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // List of Reusable Rows
                      const Divider(color: Colors.white10, height: 1),
                      MenuRow(
                        icon: Icons.person_outline,
                        title: 'Tag People',
                        subtitle: taggedUsers.isNotEmpty
                            ? taggedUsers.map((e) => e.name).join(', ')
                            : null,
                        onTap: () async {
                          final users = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TagPeopleScreen(mediaPath: widget.mediaPath),
                            ),
                          );

                          AppLogger.d("Returned users: $users");
                          AppLogger.d("Users type: ${users.runtimeType}");

                          if (!mounted) return;
                          if (users != null && users is List) {
                            setState(() {
                              taggedUsers = List<ChatUser>.from(users);
                              AppLogger.d("Updated taggedUsers: $taggedUsers");
                            });
                          }
                        },
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                      ),
                      MenuRow(
                        icon: Icons.location_on_outlined,
                        title: 'Add Location',
                        subtitle: locationName,
                        onTap: _showLocationDialog,
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                      ),
                      MenuRow(
                        icon: Icons.visibility_outlined,
                        title: 'Audience',
                        subtitle: isCloseFriends ? 'Close Friends' : 'Everyone',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AudienceScreen(
                                initialIsEveryone: isEveryone,
                                initialIsCloseFriends: isCloseFriends,
                              ),
                            ),
                          );
                          if (result != null && result is Map<String, bool>) {
                            setState(() {
                              isEveryone = result['isEveryone'] ?? true;
                              isCloseFriends =
                                  result['isCloseFriends'] ?? false;
                            });
                          }
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),

                      MenuRow(
                        icon: Icons.more_horiz,
                        title: 'More options',
                        subtitle:
                            (scheduleReel ||
                                uploadHighQuality ||
                                hideLikeCount ||
                                hideShareCount)
                            ? 'Customized preferences'
                            : null,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoreOptionScreen(
                                scheduleReel: scheduleReel,
                                uploadHighQuality: uploadHighQuality,
                                hideLikeCount: hideLikeCount,
                                hideShareCount: hideShareCount,
                              ),
                            ),
                          );
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              scheduleReel = result['schedule_reel'] ?? false;
                              uploadHighQuality =
                                  result['upload_high_quality'] ?? false;
                              hideLikeCount =
                                  result['hide_like_count'] ?? false;
                              hideShareCount =
                                  result['hide_share_count'] ?? false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: GestureDetector(
                          onTap: (_isSavingDraft || _isSharing)
                              ? null
                              : _handleSaveDraft,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: (_isSavingDraft || _isSharing)
                                  ? const Color.fromARGB(100, 120, 2, 99)
                                  : const Color.fromARGB(155, 120, 2, 99),
                            ),
                            alignment: Alignment.center,
                            child: _isSavingDraft
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFBB86FC),
                                    ),
                                  )
                                : const Text(
                                    "Save Draft",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: GestureDetector(
                          onTap: (_isSharing || _isSavingDraft)
                              ? null
                              : _handleShare,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: (_isSharing || _isSavingDraft)
                                  ? const Color.fromARGB(100, 120, 2, 99)
                                  : const Color.fromARGB(155, 120, 2, 99),
                            ),
                            alignment: Alignment.center,
                            child: _isSharing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Share",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_isVideo) {
      if (_videoController != null && _isVideoInitialized) {
        return GestureDetector(
          onTap: () {
            if (_videoController == null) return;
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              if (!_videoController!.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                    size: 42,
                  ),
                ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Check if it's a network URL or local file
    if (widget.mediaPath.startsWith('http') ||
        widget.mediaPath.startsWith('https')) {
      // Network image
      return Image.network(
        widget.mediaPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheHeight: 400,
        cacheWidth: 400,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.error, color: Colors.white, size: 48),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
      );
    } else {
      // Local file
      final file = File(widget.mediaPath);
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheHeight: 400,
        cacheWidth: 400,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.error, color: Colors.white, size: 48),
            ),
          );
        },
      );
    }
  }
}
