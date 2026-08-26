import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gruve_app/shared/widgets/cached_avatar.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_state_controller.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_provider.dart';
import 'package:gruve_app/features/home/presentation/controller/post_share_flow_bridge.dart';

import 'package:gruve_app/features/story_preview/presentation/widgets/story_action_buttons.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_top_bar.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_share_sheet.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';
import 'package:gruve_app/features/camera/presentation/widgets/sticker_overlay.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_text_editor.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_music_picker.dart';
import 'package:gruve_app/features/camera/domain/entities/filter_model.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_filter_picker.dart';
import 'package:gruve_app/features/camera/presentation/controller/filter_controller.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class StoryPreviewScreen extends StatefulWidget {
  final String mediaPath;
  final String? mediaMimeType;
  final List<StickerData> initialStickers;

  const StoryPreviewScreen({
    super.key,
    required this.mediaPath,
    this.mediaMimeType,
    this.initialStickers = const [],
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isYourStorySharing = false;
  late final List<StickerData> _stickers;
  String? _selectedStickerId;
  double _videoSpeed = 1.0;
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isPickerOrEditorOpen = false;
  bool _mediaLoadFailed = false;
  FilterModel _activeFilter = FilterModel.availableFilters.first;

  Future<String> _captureFlattenedImage() async {
    if (_isVideo) return widget.mediaPath;

    try {
      // Clear selection border before capturing
      setState(() {
        _selectedStickerId = null;
      });
      // Allow frame to render without selection border
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return widget.mediaPath;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return widget.mediaPath;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/story_flattened_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      AppLogger.d('📸 [StoryPreviewScreen] Flattened canvas captured: ${file.path}');
      return file.path;
    } catch (e) {
      AppLogger.d('❌ [StoryPreviewScreen] Error flattening canvas: $e');
      return widget.mediaPath;
    }
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

      final finalPath = await _captureFlattenedImage();

      await storyController.createStory(
         caption: '',
         mediaPath: finalPath,
         isMuted: _isMuted,
       );

      if (!mounted) return;

      if (storyController.isSuccess) {
        context.read<StoryStateController>().markStoryAsShared(
          finalPath,
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
      if (mounted) {
        setState(() {
          _isYourStorySharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _activeFilter = FilterController().selectedFilter;
    _stickers = List.from(widget.initialStickers);
    _initializeMedia();

    // ✅ OPTIMIZED: Fetch profile ONLY if cache is stale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileProvider = context.read<ProfileProvider>();
        
        // Only fetch if profile is null OR stale (>5 minutes)
        if (!profileProvider.hasFreshProfile && !profileProvider.isLoading) {
          // Fetch avatar only (skip highlights for speed)
          profileProvider.fetchAvatarOnly();
        }
      }
    });
  }

  Future<void> _initializeMedia() async {
    try {
      final resolved = await LocalMediaUtils.resolveForPreview(
        widget.mediaPath,
        mimeType: widget.mediaMimeType,
      );

      if (!mounted) return;

      if (resolved.kind == LocalMediaKind.video) {
        final controller = resolved.controller;
        if (controller == null) {
          setState(() {
            _isVideo = true;
            _mediaLoadFailed = true;
            _isInitialized = true;
          });
          return;
        }

        _videoController = controller
          ..setLooping(true)
          ..setVolume(_isMuted ? 0.0 : 1.0)
          ..play();

        setState(() {
          _isVideo = true;
          _isInitialized = true;
        });
        return;
      }

      resolved.controller?.dispose();
      setState(() {
        _isVideo = false;
        _isInitialized = true;
      });
    } catch (e) {
      AppLogger.d('❌ [StoryPreviewScreen] Media init failed: $e');
      if (!mounted) return;
      setState(() {
        _mediaLoadFailed = true;
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

  void _changeVideoSpeed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: const Color(0xEB161616),
              padding: EdgeInsets.all(context.rw(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Playback Speed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.rh(8)),
                  Text(
                    'Adjust the playback speed of this video',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: context.rf(14),
                    ),
                  ),
                  SizedBox(height: context.rh(24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSpeedOption('Slow (0.5x)', 0.5),
                      _buildSpeedOption('Normal (1.0x)', 1.0),
                      _buildSpeedOption('Fast (2.0x)', 2.0),
                    ],
                  ),
                  SizedBox(height: context.rh(16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedOption(String label, double speed) {
    final isSelected = _videoSpeed == speed;
    return GestureDetector(
      onTap: () {
        setState(() {
          _videoSpeed = speed;
          if (_videoController != null) {
            _videoController!.setPlaybackSpeed(speed);
          }
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback speed set to $label'),
            backgroundColor: const Color(0xFFC358D7),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(12)),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC358D7) : Colors.white12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white24 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF311B36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: context.rh(24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
                child: Text(
                  'Discard last clip?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.rf(20),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: context.rh(12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
                child: Text(
                  'If you continue, the last clip will be removed from your video.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: context.rf(14),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: context.rh(24)),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
                thickness: 1,
              ),
              InkWell(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.rh(16)),
                  alignment: Alignment.center,
                  child: Text(
                    'Discard',
                    style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontSize: context.rf(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
                thickness: 1,
              ),
              InkWell(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.rh(16)),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.rh(8)),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ProfileProvider>(context).user;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog(context);
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              /// MEDIA PREVIEW
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: Stack(
                          children: [
                            /// MEDIA
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStickerId = null;
                                  });
                                },
                                child: _isInitialized
                                    ? _buildMediaPreview()
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              color: Color(0xFFBB86FC),
                                            ),
                                            SizedBox(height: context.rh(16)),
                                            Text(
                                              "Loading Preview...",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: context.rf(14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),

                            ..._stickers.map((sticker) {
                              return StickerOverlay(
                                key: ValueKey(sticker.id),
                                sticker: sticker,
                                isSelected: _selectedStickerId == sticker.id,
                                onTap: () {
                                  setState(() {
                                    _selectedStickerId = sticker.id;
                                  });
                                },
                                onDelete: () {
                                  setState(() {
                                    _stickers.removeWhere((s) => s.id == sticker.id);
                                    if (_selectedStickerId == sticker.id) {
                                      _selectedStickerId = null;
                                    }
                                  });
                                },
                                onUpdate: (position, scale, rotation) {
                                  setState(() {
                                    sticker.position = position;
                                    sticker.scale = scale;
                                    sticker.rotation = rotation;
                                  });
                                },
                                onEdit: () async {
                                  if (_isPickerOrEditorOpen) return;
                                  _isPickerOrEditorOpen = true;
                                  try {
                                    if (sticker.isMusic) {
                                      final updated = await StoryMusicPicker.open(
                                        context,
                                        initialSticker: sticker,
                                      );
                                      if (updated != null && mounted) {
                                        setState(() {
                                          final index = _stickers.indexWhere((s) => s.id == sticker.id);
                                          if (index != -1) {
                                            _stickers[index] = updated;
                                          }
                                        });
                                      }
                                    } else if (sticker.isText) {
                                      final updated = await StoryTextEditor.open(
                                        context,
                                        initialSticker: sticker,
                                      );
                                      if (updated != null && mounted) {
                                        setState(() {
                                          final index = _stickers.indexWhere((s) => s.id == sticker.id);
                                          if (index != -1) {
                                            _stickers[index] = updated;
                                          }
                                        });
                                      }
                                    }
                                  } finally {
                                    _isPickerOrEditorOpen = false;
                                  }
                                },
                              );
                            }),
                          ],
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
                          StoryTopBar(
                            onClose: () async {
                              final shouldDiscard = await _showDiscardDialog(context);
                              if (shouldDiscard && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          StoryActionButtons(
                            isMuted: _isMuted,
                            onMuteToggle: _toggleMute,
                            currentSpeed: _videoSpeed,
                            onSpeedTap: _isVideo ? _changeVideoSpeed : null,
                            onTextTap: () async {
                              if (_isPickerOrEditorOpen) return;
                              _isPickerOrEditorOpen = true;
                              try {
                                final newTextSticker = await StoryTextEditor.open(context);
                                if (newTextSticker != null && mounted) {
                                  setState(() {
                                    _stickers.add(newTextSticker);
                                    _selectedStickerId = newTextSticker.id;
                                  });
                                }
                              } finally {
                                _isPickerOrEditorOpen = false;
                              }
                            },
                            onMusicTap: () async {
                              if (_isPickerOrEditorOpen) return;
                              _isPickerOrEditorOpen = true;
                              try {
                                final musicSticker = await StoryMusicPicker.open(context);
                                if (musicSticker != null && mounted) {
                                  setState(() {
                                    _stickers.add(musicSticker);
                                    _selectedStickerId = musicSticker.id;
                                  });
                                }
                              } finally {
                                _isPickerOrEditorOpen = false;
                              }
                            },
                            onFilterTap: () async {
                              if (_isPickerOrEditorOpen) return;
                              _isPickerOrEditorOpen = true;
                              try {
                                await StoryFilterPicker.open(
                                  context,
                                  initialFilter: _activeFilter,
                                  onFilterChanged: (filter) {
                                    setState(() {
                                      _activeFilter = filter;
                                    });
                                  },
                                );
                              } finally {
                                _isPickerOrEditorOpen = false;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// BOTTOM ACTION SECTION
              Container(
                height: context.rh(80),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(20),
                        vertical: context.rh(16),
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
                                height: context.rh(42),
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rw(12),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const Color(0xFF72008D),
                                ),
                                child: Row(
                                  children: [
                                    _isYourStorySharing
                                        ? SizedBox(
                                            width: context.rw(20),
                                            height: context.rh(20),
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Consumer<ProfileProvider>(
                                            builder: (context, provider, _) {
                                              return CachedAvatar(
                                                imageUrl: provider.cachedUser?.profileImage,
                                                username: provider.cachedUser?.username ?? '',
                                                radius: 13,
                                              );
                                            },
                                          ),
                                    SizedBox(
                                      width: context.rw(8),
                                    ),
                                    Text(
                                      _isYourStorySharing ? "Sharing..." : "Your Story",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.rf(14),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: context.rw(10)),

                          /// CLOSE FRIEND
                          Container(
                            height: context.rh(42),
                            padding: EdgeInsets.symmetric(horizontal: context.rw(12)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color(0xFF72008D),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: context.rw(25),
                                  height: context.rh(25),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: const Color(0xFF4CAF50),
                                    size: context.rw(20),
                                  ),
                                ),
                                SizedBox(width: context.rw(6)),
                                Text(
                                  "Close Friend",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.rf(14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: context.rw(15)),

                          /// SEND
                          GestureDetector(
                            onTap: () async {
                              AppLogger.d("\n🚀 SEND BUTTON CLICKED");
                              AppLogger.d("📤 Opening Story Share Sheet...");

                              // Show visual loader while capturing
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFC358D7)),
                                ),
                              );

                              final finalPath = await _captureFlattenedImage();

                              if (context.mounted) {
                                Navigator.pop(context); // Dismiss loading dialog
                              }

                              if (!context.mounted) return;

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
                                       mediaPath: finalPath,
                                       isMuted: _isMuted,
                                     ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: context.rw(35),
                              height: context.rh(35),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: const Color(0xFF9544A7),
                                size: context.rw(15),
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
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_mediaLoadFailed) {
      return Center(
        child: Icon(Icons.videocam_off_outlined, color: Colors.white54, size: context.rw(48)),
      );
    }

    Widget preview;
    if (_isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      preview = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      preview = Image.file(
        File(widget.mediaPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(Icons.error, color: Colors.white, size: context.rw(48)),
          );
        },
      );
    }

    if (!_activeFilter.hasMatrix) {
      return preview;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: ColorFiltered(
        key: ValueKey(_activeFilter.type),
        colorFilter: ColorFilter.matrix(_activeFilter.matrix),
        child: preview,
      ),
    );
  }
}
