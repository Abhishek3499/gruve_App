import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/camera_controller_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/top_bar.dart';
import '../widgets/side_toolbar.dart';
import '../widgets/mode_selector.dart';
import '../widgets/horizontal_filter_selector.dart';
import '../utils/camera_logger.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraControllerService _cameraService = CameraControllerService();

  @override
  void initState() {
    super.initState();
    CameraLogger.log('CameraScreen initialized');

    // Set portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initializeCamera();
    } catch (e) {
      CameraLogger.log('Failed to initialize camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CameraPreviewWidget(),

          Positioned(top: 50, left: 16, right: 16, child: TopBar()),

          Positioned(left: 02, top: 200, child: SideToolbar()),

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
      _zoomAnimationController.removeListener(listener);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        !_cameraService.isBackCamera ||
        _cameraService.isRecordingVideo) {
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
