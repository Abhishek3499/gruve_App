import 'dart:async';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:gruve_app/features/camera/presentation/controller/camera_controller_service.dart';
import 'package:gruve_app/features/camera/presentation/controller/filter_controller.dart';
import 'package:gruve_app/features/camera/domain/entities/filter_model.dart';
import 'package:gruve_app/features/camera/utils/camera_logger.dart';

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget>
    with WidgetsBindingObserver {
  final CameraControllerService _cameraService = CameraControllerService();
  final FilterController _filterController = FilterController();

  bool _isInitialized = false;
  String? _errorMessage;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  FilterModel _selectedFilter = FilterController().selectedFilter;

  StreamSubscription<bool>? _initSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<double>? _zoomSub;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = _cameraService.isInitialized;
    _currentZoom = _cameraService.displayZoom;
    _selectedFilter = _filterController.selectedFilter;
    _filterController.addListener(_onFilterChanged);
    _initializeListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCameraState();
    });
  }

  void _onFilterChanged() {
    if (!mounted) return;
    setState(() {
      _selectedFilter = _filterController.selectedFilter;
    });
  }

  void _syncCameraState() {
    if (!mounted) return;

    final controller = _cameraService.controller;
    final isReady =
        _cameraService.isInitialized &&
        controller != null &&
        controller.value.isInitialized;

    setState(() {
      _isInitialized = isReady;
      _currentZoom = _cameraService.displayZoom;
      if (isReady) {
        _errorMessage = null;
      }
    });
  }

  void _initializeListeners() {
    final initStart = DateTime.now();
    developer.log(
      '[PERF] Camera initialization started',
      name: 'CameraPreview',
    );

    _initSub = _cameraService.initializationStream.listen((isInitialized) {
      if (!mounted) return;

      if (isInitialized) {
        // Cancel any pending loading timer since the camera is ready
        _loadingTimer?.cancel();
        _loadingTimer = null;

        final initTime = DateTime.now().difference(initStart);
        developer.log(
          '[PERF] Camera initialized in ${initTime.inMilliseconds}ms',
          name: 'CameraPreview',
        );
        _currentZoom = _cameraService.displayZoom;
        _syncCameraState();
        return;
      }

      // 🚀 OPTIMIZATION: Delay showing the loader to prevent flickers
      // during extremely fast lens-switches (like switching to 0.5 zoom).
      _loadingTimer?.cancel();
      _loadingTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _errorMessage = null;
          });
        }
      });
    });

    _errorSub = _cameraService.errorStream.listen((error) {
      if (!mounted) return;
      setState(() => _errorMessage = error);
    });

    _zoomSub = _cameraService.zoomStream.listen((zoom) {
      if (!mounted) return;
      setState(() => _currentZoom = zoom);
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _cameraService.currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;

    final nextZoom = (_baseZoom * details.scale).clamp(
      _cameraService.minZoom,
      _cameraService.maxZoom,
    );

    if ((nextZoom - _cameraService.currentZoom).abs() > 0.01) {
      await _cameraService.setZoomLevel(nextZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onDoubleTap: () {
        CameraLogger.logUserAction('Double-tap detected: Flipping camera');
        _cameraService.switchCamera();
      },
      child: Stack(
        children: [
          SizedBox.expand(child: _buildFilteredCameraPreview(controller)),
          if ((_currentZoom - 1.0).abs() > 0.1)
            Positioned(
              top: 104,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilteredCameraPreview(CameraController controller) {
    final preview = FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize!.height,
        height: controller.value.previewSize!.width,
        child: CameraPreview(controller),
      ),
    );

    if (!_selectedFilter.hasMatrix) {
      return preview;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: ColorFiltered(
        key: ValueKey(_selectedFilter.type),
        colorFilter: ColorFilter.matrix(_selectedFilter.matrix),
        child: preview,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const DecoratedBox(
      key: ValueKey('camera-warming'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E002C), Color(0xFF0A0010)], // Deep premium dark violet/black gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        _errorMessage ?? 'Camera Error',
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _filterController.removeListener(_onFilterChanged);
    _initSub?.cancel();
    _errorSub?.cancel();
    _zoomSub?.cancel();
    CameraLogger.logVerbose('CameraPreviewWidget disposed');
    super.dispose();
  }
}
