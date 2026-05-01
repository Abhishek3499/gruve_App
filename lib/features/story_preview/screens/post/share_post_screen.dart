import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/story_preview/screens/audience/audience_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/more_option_screen.dart';
import 'package:gruve_app/features/story_preview/screens/post/tag_people_screen.dart';

import 'package:gruve_app/features/story_preview/api/post/menu_row.dart';

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
  @override
  void initState() {
    super.initState();
    // Initialize with tagged users if provided
    if (widget.taggedUsers != null) {
      taggedUsers = List.from(widget.taggedUsers!);
    }
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
                          onTap: () {
                            debugPrint("🔥 SHARE CLICKED");

                            final caption = captionController.text;
                            final mediaPath = widget.mediaPath;

                            final navigator = Navigator.of(context);
                            navigator.pop();
                            if (widget.popPostPreviewRouteAfterShare &&
                                navigator.canPop()) {
                              navigator.pop();
                            }
                            PostShareFlowBridge.scheduleShareUploadAfterReturningHome(
                              caption: caption,
                              mediaPath: mediaPath,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color.fromARGB(
                                155,
                                120,
                                2,
                                99,
                              ), // 👈 same as Edit Video
                            ),
                            alignment: Alignment.center,
                            child: const Text(
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
      if (widget.mediaPath.toLowerCase().endsWith('.mp4') ||
          widget.mediaPath.toLowerCase().endsWith('.mov') ||
          widget.mediaPath.toLowerCase().endsWith('.avi')) {
        // Video file - show placeholder for now
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[800],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled, color: Colors.white, size: 64),
                SizedBox(height: 8),
                Text('Video', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      } else {
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
}
