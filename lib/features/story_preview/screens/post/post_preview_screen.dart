import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/screens/post/post_preview_navigation.dart';
import 'package:gruve_app/features/story_preview/screens/post/share_post_screen.dart';
import 'package:gruve_app/features/video_editor/screens/video_editor_screen.dart';


import 'package:gruve_app/features/story_preview/api/post/post_action_buttons.dart';

import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/camera/models/sticker_data.dart';
import 'package:gruve_app/features/camera/widgets/sticker_overlay.dart';
import 'package:gruve_app/features/story_preview/widgets/story_text_editor.dart';
import 'package:gruve_app/features/story_preview/widgets/story_music_picker.dart';
import 'package:gruve_app/features/camera/models/filter_model.dart';
import 'package:gruve_app/features/story_preview/widgets/story_filter_picker.dart';
import 'package:gruve_app/features/camera/controller/filter_controller.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class PostPreviewScreen extends StatefulWidget {
  final String mediaPath;
  final String? mediaMimeType;
  final List<StickerData> initialStickers;

  const PostPreviewScreen({
    super.key,
    required this.mediaPath,
    this.mediaMimeType,
    this.initialStickers = const [],
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;
  bool _isMuted = false;
  late final List<StickerData> _stickers;
  late String _mediaPath;
  String? _selectedStickerId;
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isPickerOrEditorOpen = false;
  bool _mediaLoadFailed = false;
  FilterModel _activeFilter = FilterModel.availableFilters.first;

  @override
  void initState() {
    super.initState();
    _mediaPath = widget.mediaPath;
    _activeFilter = FilterController().selectedFilter;
    _stickers = List.from(widget.initialStickers);
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    try {
      final resolved = await LocalMediaUtils.resolveForPreview(
        _mediaPath,
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
      AppLogger.d('❌ [PostPreviewScreen] Media init failed: $e');
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

  Future<String> _captureFlattenedImage() async {
    if (_isVideo) return _mediaPath;

    try {
      // Clear selection border before capturing
      setState(() {
        _selectedStickerId = null;
      });
      // Allow frame to render without selection border
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return _mediaPath;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return _mediaPath;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/post_flattened_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      AppLogger.d('📸 [PostPreviewScreen] Flattened canvas captured: ${file.path}');
      return file.path;
    } catch (e) {
      AppLogger.d('❌ [PostPreviewScreen] Error flattening canvas: $e');
      return _mediaPath;
    }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog(context);
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop(const PostPreviewBackToCamera());
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
                                    : const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
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

                    Positioned(
                      top: 45,
                      left: 16,
                      child: BackButton(
                        color: Colors.white,
                        onPressed: () async {
                          final shouldDiscard = await _showDiscardDialog(context);
                          if (shouldDiscard && context.mounted) {
                            Navigator.of(context).pop(const PostPreviewBackToCamera());
                          }
                        },
                      ),
                    ),

                    /// TOP BAR + ACTION BUTTONS (ONE ROW)
                    Positioned(
                      bottom: 28, // 👈 important
                      left: 0,
                      right: 0,
                      child: Center(
                        child: PostActionButtons(
                          isMuted: _isMuted,
                          onMuteToggle: _toggleMute,
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
                        horizontal: context.rw(35),
                        vertical: context.rh(16),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// EDIT VIDEO (LEFT)
                          GestureDetector(
                            onTap: () async {
                              try {
                                final result = await Navigator.push<VideoEditorResult>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoEditorScreen(
                                      mediaPath: _mediaPath,
                                      initialStickers: _stickers,
                                      initialFilter: _activeFilter,
                                      initialMuted: _isMuted,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() {
                                    _mediaPath = result.trimmedPath ?? _mediaPath;
                                    _stickers.clear();
                                    _stickers.addAll(result.stickers);
                                    _activeFilter = result.filter;
                                    _isMuted = result.isMuted;
                                  });
                                  _videoController?.dispose();
                                  _videoController = null;
                                  _initializeMedia();
                                }
                              } catch (e) {
                                AppLogger.d('Error navigating to video editor: $e');
                              }
                            },
                            child: SizedBox(
                              width: context.rw(120), // 👈 control size
                              child: Container(
                                height: context.rh(42),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const ui.Color.fromARGB(155, 120, 2, 99),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Edit Video",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.rf(14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          /// NEXT (RIGHT)
                          GestureDetector(
                            onTap: () async {
                              try {
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

                                AppLogger.d(
                                  'PostPreviewScreen navigating with mediaPath: $finalPath',
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SharePostScreen(
                                      mediaPath: finalPath,
                                      mediaMimeType: widget.mediaMimeType,
                                      popPostPreviewRouteAfterShare: true,
                                      isMuted: _isMuted,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                AppLogger.d('Navigation error: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error navigating: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: SizedBox(
                              width: context.rw(100), // 👈 thoda chhota
                              child: Container(
                                height: context.rh(42),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const ui.Color.fromARGB(155, 120, 2, 99),
                                ),
                                alignment: Alignment.center,
                                child: const Text("Next"),
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
        File(_mediaPath),
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
