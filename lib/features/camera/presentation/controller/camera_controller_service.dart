import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:gruve_app/features/camera/utils/camera_logger.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';
import 'package:gruve_app/features/camera/presentation/controller/filter_controller.dart';

class CameraControllerService {
  static final CameraControllerService _instance =
      CameraControllerService._internal();

  factory CameraControllerService() => _instance;

  CameraControllerService._internal();

  // 🚀 OPTIMIZATION: Cache available cameras globally
  static List<CameraDescription>? _cachedCameras;

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  int _defaultBackCameraIndex = 0;
  int? _ultraWideCameraIndex;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isRecordingVideo = false;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _displayZoom = 1.0;

  final StreamController<bool> _initializationStreamController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _captureStreamController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _videoRecordingStreamController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  final StreamController<FlashMode> _flashModeStreamController =
      StreamController<FlashMode>.broadcast();
  final StreamController<double> _zoomStreamController =
      StreamController<double>.broadcast();

  Stream<bool> get initializationStream =>
      _initializationStreamController.stream;
  Stream<bool> get captureStream => _captureStreamController.stream;
  Stream<bool> get videoRecordingStream =>
      _videoRecordingStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  Stream<FlashMode> get flashModeStream => _flashModeStreamController.stream;
  Stream<double> get zoomStream => _zoomStreamController.stream;

  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isRecordingVideo => _isRecordingVideo;
  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  int get currentCameraIndex => _currentCameraIndex;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get currentZoom => _currentZoom;
  double get displayZoom => _displayZoom;
  bool get isBackCamera =>
      _cameras.isNotEmpty &&
      _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.back;
  bool get hasUltraWideCamera =>
      isBackCamera &&
      _ultraWideCameraIndex != null &&
      _currentCameraIndex != _ultraWideCameraIndex;

  FlashMode get currentFlashMode {
    if (_controller == null || !_isInitialized) return FlashMode.off;
    return _controller!.value.flashMode;
  }

  bool get _isUltraWideActive =>
      _ultraWideCameraIndex != null &&
      _currentCameraIndex == _ultraWideCameraIndex;

  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    try {
      final currentMode = _controller!.value.flashMode;
      final nextMode = currentMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _controller!.setFlashMode(nextMode);
      _flashModeStreamController.add(nextMode);
    } catch (e) {
      _errorStreamController.add('Failed to toggle flash: ${e.toString()}');
    }
  }

  Future<void> initializeCamera() async {
    if (_isInitialized) {
      _initializationStreamController.add(true);
      _zoomStreamController.add(_displayZoom);
      return;
    }

    try {
      CameraLogger.logInitializationStart();

      // 🚀 OPTIMIZATION 1: Use permanently cached cameras if available (lenses never change during app session)
      if (_cachedCameras != null && _cachedCameras!.isNotEmpty) {
        _cameras = _cachedCameras!;
        CameraLogger.log('Using cached cameras (fast path)');
      } else {
        _cameras = await availableCameras();
        _cachedCameras = _cameras;
        CameraLogger.log('Loaded cameras from system');
      }

      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      _prepareCameraIndexes();

      await _initializeControllerAt(_defaultBackCameraIndex);

      // 🚀 OPTIMIZATION 3: Set zoom asynchronously (don't block)
      unawaited(setZoomLevel(1.0));

      _isInitialized = true;
      CameraLogger.logInitializationSuccess();
      _initializationStreamController.add(true);
      _zoomStreamController.add(_displayZoom);
    } catch (e) {
      final cameraName = _cameras.isEmpty ? 'unknown' : _cameras.first.name;
      CameraLogger.log('Failed to initialize camera: $cameraName');
      _errorStreamController.add(
        'Camera initialization failed: ${e.toString()}',
      );
      _initializationStreamController.add(false);
    }
  }

  Future<void> initialize() async {
    await initializeCamera();
  }

  // 🚀 NEW: Pre-warm camera in background for instant opening
  static Future<void> prewarmCamera() async {
    try {
      // Cache available cameras in background
      if (_cachedCameras == null || _cachedCameras!.isEmpty) {
        _cachedCameras = await availableCameras();
        CameraLogger.log('✅ Camera pre-warmed successfully');
      }
    } catch (e) {
      CameraLogger.log('⚠️ Camera pre-warm failed (non-critical): $e');
    }
  }

  void _prepareCameraIndexes() {
    final backIndexes = <int>[];

    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        backIndexes.add(i);
      }
    }

    if (backIndexes.isEmpty) {
      _defaultBackCameraIndex = 0;
      _ultraWideCameraIndex = null;
      return;
    }

    _defaultBackCameraIndex = backIndexes.first;
    _ultraWideCameraIndex = backIndexes.length > 1 ? backIndexes.last : null;
  }

  Future<void> _initializeControllerAt(int cameraIndex) async {
    _currentCameraIndex = cameraIndex;

    // 🚀 OPTIMIZATION 4: Use medium resolution for faster initialization
    _controller = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    // The camera plugin defaults a freshly-initialized controller's flash
    // mode to `auto`, not `off` — but the toolbar's flash icon treats any
    // non-off mode as "on". Without this, the icon would show "on" right
    // after opening the camera (or switching lenses) while the flash
    // hardware itself is actually just idle in auto mode, one tap behind
    // what the icon displays. Reset explicitly so hardware state and the
    // icon's default "off" both start in sync. Wrapped in try/catch since
    // some lenses (e.g. most front cameras) have no flash hardware at all.
    try {
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) {
      CameraLogger.log('Flash mode reset skipped (no flash hardware?): $e');
    }
    _flashModeStreamController.add(_controller!.value.flashMode);

    // 🚀 OPTIMIZATION: Run camera settings and zoom queries in the background
    // so the preview stream starts rendering immediately without any delay!
    unawaited(() async {
      try {
        await Future.wait([
          _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp),
          _controller!.setFocusMode(FocusMode.auto),
        ]);

        final zoomLevels = await Future.wait([
          _controller!.getMinZoomLevel(),
          _controller!.getMaxZoomLevel(),
        ]);

        _minZoom = zoomLevels[0];
        _maxZoom = zoomLevels[1];
        _currentZoom = _minZoom;
        _appliedZoom = _minZoom;
        visualZoomScale.value = 1.0;
        _displayZoom = _isUltraWideActive ? 0.5 : _currentZoom;
        _zoomStreamController.add(_displayZoom);
      } catch (e) {
        CameraLogger.log('Background camera configuration failed: $e');
      }
    }());
  }

  /// Sets the zoom target. The actual zoom eases toward it every frame
  /// (in log space, so it feels even across the range, like the iPhone
  /// camera) instead of jumping between the coarse steps a pinch/drag gives.
  Future<void> setZoomLevel(double zoomLevel) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _targetZoom = zoomLevel.clamp(_minZoom, _maxZoom);
    _zoomTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _stepZoom(),
    );
  }

  double _targetZoom = 1.0;
  double _lastNativeZoom = 1.0;

  // The native zoom call is slow on some devices (hundreds of ms while the
  // encoder runs). The preview scales by currentZoom / appliedZoom right away
  // so zooming looks instant; the factor returns to 1 as native catches up.
  double _appliedZoom = 1.0;
  final ValueNotifier<double> visualZoomScale = ValueNotifier(1.0);

  void _updateVisualScale() {
    final target = (_currentZoom / _appliedZoom).clamp(0.6, 4.0);
    final current = visualZoomScale.value;
    // While zooming, ease toward the target so native apply steps don't pop.
    final scale = _zoomTimer != null
        ? current + (target - current) * 0.5
        : target;
    if ((current - scale).abs() > 0.001) {
      visualZoomScale.value = scale;
    }
  }

  Timer? _zoomTimer;

  void _stopZoomTimer() {
    _zoomTimer?.cancel();
    _zoomTimer = null;
  }

  void _stepZoom() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _stopZoomTimer();
      return;
    }

    final from = _currentZoom.clamp(0.01, double.infinity);
    final to = _targetZoom.clamp(0.01, double.infinity);
    final next = (to - from).abs() < 0.005
        ? _targetZoom
        : exp(log(from) + (log(to) - log(from)) * 0.3);

    _currentZoom = next;
    _displayZoom = _isUltraWideActive ? 0.5 : next;
    _zoomStreamController.add(_displayZoom);
    _updateVisualScale();
    // Each native zoom rebuilds the camera capture request; skip changes too
    // small to see, but always send the final value.
    if (next == _targetZoom || (next - _lastNativeZoom).abs() > 0.02) {
      _lastNativeZoom = next;
      _sendNativeZoom(next);
    }

    if (next == _targetZoom) _stopZoomTimer();
  }

  // Keep only one native call in flight and always send the latest value.
  Future<void> _sendNativeZoom(double zoom) async {
    _pendingNativeZoom = zoom;
    if (_zoomCallInFlight) return;
    _zoomCallInFlight = true;
    try {
      while (_pendingNativeZoom != null) {
        final next = _pendingNativeZoom!;
        _pendingNativeZoom = null;
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) return;
        await controller.setZoomLevel(next);
        // The native call returns a little before the new zoom shows up in
        // preview frames; delay so the scale doesn't drop before the picture
        // actually changes (that mismatch looked like stutter).
        Timer(const Duration(milliseconds: 90), () {
          _appliedZoom = next;
          _updateVisualScale();
        });
      }
    } catch (e) {
      CameraLogger.log('setZoomLevel failed: $e');
    } finally {
      _zoomCallInFlight = false;
    }
  }

  bool _zoomCallInFlight = false;
  double? _pendingNativeZoom;

  Future<void> setScale(double scale) async {
    if (!_isInitialized) return;

    if (scale == 0.5 && _ultraWideCameraIndex != null) {
      await _switchToCameraIndex(_ultraWideCameraIndex!, displayZoom: 0.5);
      return;
    }

    if (_isUltraWideActive) {
      await _switchToCameraIndex(_defaultBackCameraIndex);
    }

    await setZoomLevel(scale);
  }

  Future<void> _switchToCameraIndex(
    int cameraIndex, {
    double? displayZoom,
  }) async {
    if (_currentCameraIndex == cameraIndex && _isInitialized) {
      if (displayZoom != null) {
        _displayZoom = displayZoom;
        _zoomStreamController.add(_displayZoom);
      }
      return;
    }

    _stopZoomTimer();
    try {
      await _controller?.dispose();
      _isInitialized = false;
      _initializationStreamController.add(false);

      // 🚀 OPTIMIZATION: Wait 110ms for the native Camera2 driver to fully release the hardware lock.
      // This completely prevents native thread contention (blocks for 344ms+) and makes the lens switch perfectly smooth.
      await Future<void>.delayed(const Duration(milliseconds: 110));

      await _initializeControllerAt(cameraIndex);
      if (displayZoom != null) {
        _displayZoom = displayZoom;
      }
      // Set zoom asynchronously to avoid blocking the transition
      unawaited(_controller!.setZoomLevel(_minZoom));
      _currentZoom = _minZoom;
      _appliedZoom = _minZoom;
      visualZoomScale.value = 1.0;
      _targetZoom = _minZoom;

      _isInitialized = true;
      _initializationStreamController.add(true);
      _zoomStreamController.add(_displayZoom);
      _flashModeStreamController.add(_controller!.value.flashMode);
    } catch (e) {
      _errorStreamController.add('Failed to switch camera: ${e.toString()}');
    }
  }

  Future<void> switchCamera() async {
    if (!_isInitialized || _cameras.length <= 1) return;

    try {
      final currentDirection = _cameras[_currentCameraIndex].lensDirection;
      final nextIndex = currentDirection == CameraLensDirection.front
          ? _defaultBackCameraIndex
          : _cameras.indexWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
            );

      if (nextIndex < 0) return;

      await _switchToCameraIndex(nextIndex, displayZoom: 1.0);
    } catch (e) {
      _errorStreamController.add('Failed to switch camera: ${e.toString()}');
    }
  }

  Future<XFile?> captureImage() async {
    if (!_isInitialized || _isCapturing || _isRecordingVideo) return null;

    try {
      _isCapturing = true;
      _captureStreamController.add(true);

      final image = await _controller!.takePicture();
      final filter = FilterController().selectedFilter;

      if (!filter.hasMatrix) {
        return image;
      }

      final imageFile = File(image.path);
      final processedFile = await ImageFilterProcessor.resizeImageIfNeeded(
        imageFile,
      );
      final filteredFile = await ImageFilterProcessor.applyColorMatrixToImage(
        processedFile,
        filter.matrix,
      );

      if (processedFile.path != imageFile.path) {
        await processedFile.delete();
      }

      await imageFile.delete();

      CameraLogger.log('Filter applied: ${filter.name}');
      return XFile(filteredFile.path);
    } catch (e) {
      _errorStreamController.add('Failed to capture image: ${e.toString()}');
      return null;
    } finally {
      _isCapturing = false;
      _captureStreamController.add(false);
    }
  }

  Future<void> startVideoRecording() async {
    if (!_isInitialized || _isCapturing || _isRecordingVideo) return;

    lastRecordingError = null;
    try {
      _isRecordingVideo = true;
      _videoRecordingStreamController.add(true);

      await _controller!.startVideoRecording();
      CameraLogger.log('Video recording started');
    } catch (e) {
      _isRecordingVideo = false;
      _videoRecordingStreamController.add(false);
      // Not sent to errorStream: that replaces the whole preview with text.
      lastRecordingError = e.toString();
      CameraLogger.log('Failed to start video recording: $e');
    }
  }

  /// Message of the last failed start/stop, shown by the UI in a snackbar.
  String? lastRecordingError;

  Future<XFile?> stopVideoRecording() async {
    if (!_isRecordingVideo) return null;

    // The native side can stop recording on its own (e.g. storage/hardware
    // error) without us knowing. If that happened, calling stopVideoRecording()
    // again throws "No video is recording" - treat that as already-stopped
    // instead of surfacing a scary error to the user.
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      CameraLogger.log('Stop requested but recording was already stopped');
      return null;
    }

    try {
      final video = await _controller!.stopVideoRecording();
      CameraLogger.log('Video recording stopped: ${video.path}');
      return video;
    } catch (e) {
      CameraLogger.log('Failed to stop video recording: $e');
      lastRecordingError = e.toString();
      return null;
    } finally {
      _isRecordingVideo = false;
      _videoRecordingStreamController.add(false);
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _initializationStreamController.add(false);
  }

  void disposeStreams() {
    _initializationStreamController.close();
    _captureStreamController.close();
    _videoRecordingStreamController.close();
    _errorStreamController.close();
    _flashModeStreamController.close();
    _zoomStreamController.close();
  }
}
