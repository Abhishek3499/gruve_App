import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';

import 'package:gruve_app/features/story_preview/widgets/story_action_buttons.dart';
import 'package:gruve_app/features/story_preview/widgets/story_top_bar.dart';
import 'package:gruve_app/core/widgets/story_share_sheet.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class StoryPreviewScreen extends StatefulWidget {
  final String mediaPath;

  const StoryPreviewScreen({super.key, required this.mediaPath});

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isYourStorySharing = false;

  Widget _buildUserAvatar(String? imageUrl, String username) {
    final trimmed = imageUrl?.trim() ?? '';
    if (trimmed.startsWith('http')) {
      return CircleAvatar(
        radius: 13,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(trimmed),
      );
    }
    final fallbackLetter = username.isNotEmpty ? username[0].toUpperCase() : '';
    return CircleAvatar(
      radius: 13,
      backgroundColor: Colors.white12,
      backgroundImage: fallbackLetter.isEmpty
          ? const AssetImage(AppAssets.profile)
          : null,
      child: fallbackLetter.isEmpty
          ? null
          : Text(
              fallbackLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _shareToYourStory() async {
    if (_isYourStorySharing) return;

    setState(() {
      _isYourStorySharing = true;
    });

    try {
      final storyController = Provider.of<StoryController>(
        context,
        listen: false,
      );

      await storyController.createStory(
        caption: '',
        mediaPath: widget.mediaPath,
      );

      if (!mounted) return;

      if (storyController.isSuccess) {
        context.read<StoryStateController>().markStoryAsShared(
          widget.mediaPath,
        );

        // Notify that the counts/story changed so Profile screen updates.
        ProfileCountRefreshBridge.notifyCountsChanged(reason: 'story_shared');

        final navigator = Navigator.of(context);
        PostShareFlowBridge.notifyStorySharedNavigateToProfile();
        navigator.popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isYourStorySharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(storyController.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isYourStorySharing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share story: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeMedia();

    // Fetch own profile data if not loaded yet so that the avatar image is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        if (profileProvider.user == null && !profileProvider.isLoading) {
          profileProvider.fetchProfileData(fetchUserReason: 'story_preview_init');
        }
      }
    });
  }

  void _initializeMedia() async {
    final file = File(widget.mediaPath);

    _isVideo =
        widget.mediaPath.toLowerCase().endsWith('.mp4') ||
        widget.mediaPath.toLowerCase().endsWith('.mov') ||
        widget.mediaPath.toLowerCase().endsWith('.avi');

    if (_isVideo) {
      _videoController = VideoPlayerController.file(file);

      await _videoController!.initialize();

      _videoController!
        ..setLooping(true)
        ..setVolume(_isMuted ? 0.0 : 1.0)
        ..play();

      setState(() {
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _toggleMute() {
    if (_videoController != null) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    } else {
      setState(() {
        _isMuted = !_isMuted;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ProfileProvider>(context).user;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// MEDIA PREVIEW
            Expanded(
              child: Stack(
                children: [
                  /// MEDIA
                  Positioned.fill(
                    child: _isInitialized
                        ? _buildMediaPreview()
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),

                  /// TOP BAR + ACTION BUTTONS (ONE ROW)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        StoryTopBar(onClose: () => Navigator.pop(context)),
                        StoryActionButtons(
                          isMuted: _isMuted,
                          onMuteToggle: _toggleMute,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// BOTTOM ACTION SECTION
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                    child: Row(
                      children: [
                        /// YOUR STORY
                        Expanded(
                          child: GestureDetector(
                            onTap: _isYourStorySharing ? null : _shareToYourStory,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: const Color(0xFF72008D),
                              ),
                              child: Row(
                                children: [
                                  _isYourStorySharing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : _buildUserAvatar(
                                          user?.profileImage,
                                          user?.username ?? '',
                                        ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    _isYourStorySharing ? "Sharing..." : "Your Story",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// CLOSE FRIEND
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Color(0xFF72008D),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 25,
                                height: 25,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Close Friend",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 15),

                        /// SEND
                        GestureDetector(
                          onTap: () {
                            debugPrint("\n🚀 SEND BUTTON CLICKED");
                            debugPrint("📤 Opening Story Share Sheet...");
                            debugPrint("📁 MediaPath: ${widget.mediaPath}");

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (bottomSheetContext) {
                                return ChangeNotifierProvider.value(
                                  value: Provider.of<StoryController>(
                                    context,
                                    listen: false,
                                  ),
                                  child: StoryShareSheet(
                                    mediaPath: widget.mediaPath,
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF9544A7),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_isVideo && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return Image.file(
      File(widget.mediaPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        );
      },
    );
  }
}
