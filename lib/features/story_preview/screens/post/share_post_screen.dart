import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/story_preview/screens/audience/audience_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/more_option_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/tag_people_screen.dart';

import 'package:gruve_app/features/story_preview/api/post/menu_row.dart';
import 'package:video_player/video_player.dart';

class SharePostScreen extends StatefulWidget {
  final String mediaPath;
  final List<ChatUser>? taggedUsers;

  /// When [SharePostScreen] was pushed from [PostPreviewScreen], pop that route
  /// after share so the user returns to the home feed (camera flow is already gone).
  /// When opened from a sheet or with PostPreview already popped, keep `false`.
  final bool popPostPreviewRouteAfterShare;

  const SharePostScreen({
    super.key,
    required this.mediaPath,
    this.taggedUsers,
    this.popPostPreviewRouteAfterShare = false,
  });

  @override
  State<SharePostScreen> createState() => _SharePostScreenState();
}

class _SharePostScreenState extends State<SharePostScreen> {
  List<ChatUser> selectedUsers = [];
  List<ChatUser> taggedUsers = [];
  TextEditingController captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isVideoInitialized = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
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
      await _videoController!.setLooping(true);
      await _videoController!.play();

      if (!mounted) return;
      setState(() => _isVideoInitialized = true);
    } catch (e) {
      debugPrint('SharePostScreen video preview error: $e');
      if (!mounted) return;
      setState(() => _isVideoInitialized = false);
    }
  }

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  void _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    debugPrint("🔥 SHARE CLICKED");

    final caption = captionController.text;
    final mediaPath = widget.mediaPath;

    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    final navigator = Navigator.of(context);
    navigator.pop();
    if (widget.popPostPreviewRouteAfterShare && navigator.canPop()) {
      navigator.pop();
    }

    PostShareFlowBridge.scheduleShareUploadAfterReturningHome(
      caption: caption,
      mediaPath: mediaPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    debugPrint('SharePostScreen received mediaPath: ${widget.mediaPath}');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0214), // Dark purple background
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            colors: [Color(0xFF2A0944), Color(0xFF0D0214)],
            radius: 1.5,
          ),
        ),
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

                          debugPrint("Returned users: $users");
                          debugPrint("Users type: ${users.runtimeType}");

                          if (!mounted) return;
                          if (users != null && users is List) {
                            setState(() {
                              taggedUsers = List<ChatUser>.from(users);
                              debugPrint("Updated taggedUsers: $taggedUsers");
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
                        onTap: () {},
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                      ),
                      MenuRow(
                        icon: Icons.visibility_outlined,
                        title: 'Audience',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AudienceScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),

                      MenuRow(
                        icon: Icons.more_horiz,
                        title: 'More options',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MoreOptionScreen(),
                            ),
                          );
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
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color.fromARGB(155, 120, 2, 99),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
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
                          onTap: _isSharing ? null : _handleShare,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: _isSharing
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
        return Stack(
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
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white70,
                size: 42,
              ),
            ),
          ],
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
      // Image file
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
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
