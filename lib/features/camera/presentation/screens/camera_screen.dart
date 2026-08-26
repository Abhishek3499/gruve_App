import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_music_picker.dart';
import 'package:gruve_app/features/camera/presentation/controller/camera_controller_service.dart';
import 'package:gruve_app/features/camera/presentation/widgets/camera_preview_widget.dart';
import 'package:gruve_app/features/camera/presentation/widgets/top_bar.dart';
import 'package:gruve_app/features/camera/presentation/widgets/side_toolbar.dart';
import 'package:gruve_app/features/camera/presentation/widgets/mode_selector.dart';
import 'package:gruve_app/features/camera/presentation/widgets/horizontal_filter_selector.dart';
import 'package:gruve_app/features/camera/utils/camera_logger.dart';
import 'package:gruve_app/features/camera/data/datasource/mode_service.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';
import 'package:gruve_app/features/camera/presentation/controller/filter_controller.dart';
import 'package:gruve_app/features/camera/presentation/widgets/sticker_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraControllerService _cameraService = CameraControllerService();
  String? _selectedStickerId;
  bool _isPickerOpen = false;

  @override
  void initState() {
    super.initState();
    CameraLogger.log('CameraScreen initialized');

    // Reset filters to Normal when opening the camera screen
    FilterController().reset();

    ModeService().clearStickers();
    ModeService().setShootDuration(0);
    ModeService().addListener(_onStickersChanged);

    // Set portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    unawaited(_initializeCamera());
  }

  void _onStickersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initializeCamera();
    } catch (e) {
      CameraLogger.log('Failed to initialize camera: $e');
    }
  }

  Future<void> _pickMusic() async {
    if (_isPickerOpen) return;
    _isPickerOpen = true;
    try {
      final musicSticker = await StoryMusicPicker.open(context);
      if (musicSticker != null && mounted) {
        ModeService().addSticker(musicSticker);
        setState(() {
          _selectedStickerId = musicSticker.id;
        });
      }
    } catch (e) {
      CameraLogger.log('Error opening music picker: $e');
    } finally {
      _isPickerOpen = false;
    }
  }

  void _showTimerSelection() {
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Shoot Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose video duration (includes 3s countdown)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimerOption('Off', 0),
                      _buildTimerOption('5 Seconds', 5),
                      _buildTimerOption('10 Seconds', 10),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(String label, int seconds) {
    final isSelected = ModeService().shootDuration == seconds;
    return GestureDetector(
      onTap: () {
        ModeService().setShootDuration(seconds);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(seconds == 0 ? 'Timer turned off' : 'Timer set for $label shooting'),
            backgroundColor: const Color(0xFFC358D7),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildSelectedMusicBadge() {
    return const SizedBox.shrink();
  }

  Widget _buildCountdownOverlay() {
    if (!ModeService().isCountdownRunning) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '${ModeService().countdownValue}',
                  key: ValueKey(ModeService().countdownValue),
                  style: const TextStyle(
                    color: Color(0xFFC358D7),
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  ModeService().cancelCountdown();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text(
                  'Cancel Timer',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStickerId = null;
              });
            },
            child: const CameraPreviewWidget(),
          ),

          ...ModeService().stickers.map((sticker) {
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
                ModeService().removeSticker(sticker.id);
                if (_selectedStickerId == sticker.id) {
                  setState(() {
                    _selectedStickerId = null;
                  });
                }
              },
              onUpdate: (position, scale, rotation) {
                ModeService().updateSticker(
                  sticker.id,
                  position,
                  scale,
                  rotation,
                );
              },
            );
          }),

          Positioned(top: 50, left: 16, right: 16, child: TopBar()),

          _buildSelectedMusicBadge(),

          Positioned(
            left: 02,
            top: 200,
            child: SideToolbar(
              onMusicTap: _pickMusic,
              onTimerTap: _showTimerSelection,
              onEmojiSelected: (emoji) {
                final newSticker = StickerData(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  text: emoji,
                  position: const Offset(150, 250),
                );
                ModeService().addSticker(newSticker);
                setState(() {
                  _selectedStickerId = newSticker.id;
                });
              },
            ),
          ),

          _buildCountdownOverlay(),

          Positioned(
            bottom: 228,
            left: 0,
            right: 0,
            child: Center(child: _CameraZoomSelector()),
          ),

          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: HorizontalFilterSelector(),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(child: ModeSelector()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    CameraLogger.log('CameraScreen disposing');
    ModeService().removeListener(_onStickersChanged);
    _cameraService.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }
}

class _CameraZoomSelector extends StatefulWidget {
  const _CameraZoomSelector();

  @override
  State<_CameraZoomSelector> createState() => _CameraZoomSelectorState();
}

class _CameraZoomSelectorState extends State<_CameraZoomSelector>
    with SingleTickerProviderStateMixin {
  final CameraControllerService _cameraService = CameraControllerService();

  late final AnimationController _zoomAnimationController;
  StreamSubscription<bool>? _initSub;
  StreamSubscription<bool>? _recordingSub;
  StreamSubscription<double>? _zoomSub;

  bool _isInitialized = false;
  double _selectedZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _isInitialized = _cameraService.isInitialized;
    _selectedZoom = _cameraService.displayZoom;

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _initSub = _cameraService.initializationStream.listen((isInitialized) {
      if (!mounted) return;
      setState(() {
        _isInitialized = isInitialized;
        _selectedZoom = _cameraService.displayZoom;
      });
    });

    _zoomSub = _cameraService.zoomStream.listen((zoom) {
      if (!mounted) return;
      setState(() => _selectedZoom = zoom);
    });

    _recordingSub = _cameraService.videoRecordingStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _initSub?.cancel();
    _recordingSub?.cancel();
    _zoomSub?.cancel();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  Future<void> _selectZoom(double zoom) async {
    if (!_cameraService.isInitialized) return;

    CameraLogger.logUserAction('Zoom ${zoom.toStringAsFixed(1)}x selected');

    if (zoom == 0.5) {
      await _cameraService.setScale(0.5);
      return;
    }

    if ((_cameraService.displayZoom - 0.5).abs() < 0.1) {
      await _cameraService.setScale(zoom);
      return;
    }

    final begin = _cameraService.currentZoom;
    final end = zoom.clamp(_cameraService.minZoom, _cameraService.maxZoom);
    final animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _zoomAnimationController, curve: Curves.easeOut),
    );

    void listener() {
      _cameraService.setZoomLevel(animation.value);
    }

    _zoomAnimationController
      ..stop()
      ..reset();
    _zoomAnimationController.addListener(listener);
    try {
      await _zoomAnimationController.forward();
    } finally {
      if (mounted) {
        _zoomAnimationController.removeListener(listener);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        !_cameraService.isBackCamera) {
      return const SizedBox.shrink();
    }

    final options = <double>[
      if (_cameraService.hasUltraWideCamera || _selectedZoom == 0.5) 0.5,
      1.0,
      if (_cameraService.maxZoom >= 2.0) 2.0,
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map(_buildZoomButton).toList(),
      ),
    );
  }

  Widget _buildZoomButton(double zoom) {
    final isSelected = (_selectedZoom - zoom).abs() < 0.15;

    return GestureDetector(
      onTap: () => _selectZoom(zoom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: isSelected ? 44 : 36,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          zoom == 0.5
              ? '.5'
              : zoom == 1.0
              ? '1x'
              : '${zoom.toInt()}x',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: isSelected ? 13 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
