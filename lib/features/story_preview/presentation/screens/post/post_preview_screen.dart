import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_share_flow_bridge.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/drafts_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/post/post_preview_navigation.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/post/share_post_screen.dart';
import 'package:gruve_app/features/video_editor/presentation/screens/video_editor_screen.dart';

import 'package:gruve_app/features/story_preview/presentation/widgets/post/post_action_buttons.dart';

import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';
import 'package:gruve_app/features/camera/presentation/widgets/sticker_overlay.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_text_editor.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_music_picker.dart';
import 'package:gruve_app/features/camera/domain/entities/filter_model.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_filter_picker.dart';
import 'package:gruve_app/features/camera/presentation/controller/filter_controller.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

/// What the user chose when backing out of the post preview without posting.
enum _PostExitAction { saveDraft, discard, cancel }

class PostPreviewScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends ConsumerState<PostPreviewScreen> {
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
  bool _isSavingDraft = false;
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

      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return _mediaPath;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return _mediaPath;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File(
        '${tempDir.path}/post_flattened_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      AppLogger.d(
        '📸 [PostPreviewScreen] Flattened canvas captured: ${file.path}',
      );
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

  Widget _buildExitDialogOption(
    BuildContext context, {
    required String label,
    required Color color,
    required FontWeight weight,
    required _PostExitAction action,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, action),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.rh(16)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: context.rf(16),
            fontWeight: weight,
          ),
        ),
      ),
    );
  }

  Future<_PostExitAction> _showDiscardDialog(BuildContext context) async {
    final divider = Divider(
      color: Colors.white.withValues(alpha: 0.1),
      height: 1,
      thickness: 1,
    );

    final result = await showDialog<_PostExitAction>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.chatBackground,
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
                  'Leave without posting?',
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
                  'Save this as a draft to finish later, or discard it.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: context.rf(14),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: context.rh(24)),
              divider,
              _buildExitDialogOption(
                context,
                label: 'Save Draft',
                color: Colors.white,
                weight: FontWeight.w600,
                action: _PostExitAction.saveDraft,
              ),
              divider,
              _buildExitDialogOption(
                context,
                label: 'Discard',
                color: const Color(0xFFE53935),
                weight: FontWeight.bold,
                action: _PostExitAction.discard,
              ),
              divider,
              _buildExitDialogOption(
                context,
                label: 'Cancel',
                color: Colors.white,
                weight: FontWeight.w500,
                action: _PostExitAction.cancel,
              ),
              SizedBox(height: context.rh(8)),
            ],
          ),
        );
      },
    );
    return result ?? _PostExitAction.cancel;
  }

  Future<void> _handleExitAction(_PostExitAction action) async {
    if (!context.mounted) return;
    switch (action) {
      case _PostExitAction.discard:
        Navigator.of(context).pop(const PostPreviewBackToCamera());
      case _PostExitAction.saveDraft:
        await _saveDraftAndExit();
      case _PostExitAction.cancel:
        break;
    }
  }

  Future<void> _saveDraftAndExit() async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.accentPurple),
      ),
    );

    try {
      final finalPath = await _captureFlattenedImage();
      await ref
          .read(draftsNotifierProvider.notifier)
          .saveDraft(mediaPath: finalPath, mediaMimeType: widget.mediaMimeType);

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading dialog

      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.isFirst);
      PostShareFlowBridge.onRequestShowProfileTab?.call();
    } catch (e) {
      AppLogger.d('[PostPreviewScreen] Save draft failed: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading dialog
      setState(() => _isSavingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final action = await _showDiscardDialog(context);
        await _handleExitAction(action);
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
                                    _stickers.removeWhere(
                                      (s) => s.id == sticker.id,
                                    );
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
                                      final updated =
                                          await StoryMusicPicker.open(
                                            context,
                                            initialSticker: sticker,
                                          );
                                      if (updated != null && mounted) {
                                        setState(() {
                                          final index = _stickers.indexWhere(
                                            (s) => s.id == sticker.id,
                                          );
                                          if (index != -1) {
                                            _stickers[index] = updated;
                                          }
                                        });
                                      }
                                    } else if (sticker.isText) {
                                      final updated =
                                          await StoryTextEditor.open(
                                            context,
                                            initialSticker: sticker,
                                          );
                                      if (updated != null && mounted) {
                                        setState(() {
                                          final index = _stickers.indexWhere(
                                            (s) => s.id == sticker.id,
                                          );
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
                          final action = await _showDiscardDialog(context);
                          await _handleExitAction(action);
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
                              final newTextSticker = await StoryTextEditor.open(
                                context,
                              );
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
                              final musicSticker = await StoryMusicPicker.open(
                                context,
                              );
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
                                // Fully release this controller (not just pause) before
                                // VideoEditorScreen opens its own on the same file — the
                                // underlying hardware decoder/texture stays attached until
                                // dispose(), and most devices only support one decoder
                                // instance per file, so a mere pause() still made the
                                // editor's controller fail to initialize.
                                _videoController?.dispose();
                                _videoController = null;

                                final result =
                                    await Navigator.push<VideoEditorResult>(
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
                                if (!mounted) return;

                                if (result != null) {
                                  setState(() {
                                    _mediaPath =
                                        result.trimmedPath ?? _mediaPath;
                                    _stickers.clear();
                                    _stickers.addAll(result.stickers);
                                    _activeFilter = result.filter;
                                    _isMuted = result.isMuted;
                                  });
                                }
                                _initializeMedia();
                              } catch (e) {
                                AppLogger.d(
                                  'Error navigating to video editor: $e',
                                );
                              }
                            },
                            child: SizedBox(
                              width: context.rw(120), // 👈 control size
                              child: Container(
                                height: context.rh(42),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const ui.Color.fromARGB(
                                    155,
                                    120,
                                    2,
                                    99,
                                  ),
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
                                    child: CircularProgressIndicator(
                                      color: AppColors.accentPurple,
                                    ),
                                  ),
                                );

                                final finalPath =
                                    await _captureFlattenedImage();

                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Dismiss loading dialog
                                }

                                if (!context.mounted) return;

                                // Fully release this controller (not just pause) before
                                // SharePostScreen opens its own controller on the same
                                // file — otherwise the two decoder instances contend and
                                // SharePostScreen's controller can fail to initialize.
                                _videoController?.dispose();
                                _videoController = null;

                                AppLogger.d(
                                  'PostPreviewScreen navigating with mediaPath: $finalPath',
                                );
                                await Navigator.push(
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

                                if (mounted && _isVideo) {
                                  _initializeMedia();
                                }
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
                                  color: const ui.Color.fromARGB(
                                    155,
                                    120,
                                    2,
                                    99,
                                  ),
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
        child: Icon(
          Icons.videocam_off_outlined,
          color: Colors.white54,
          size: context.rw(48),
        ),
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
