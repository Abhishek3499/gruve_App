import 'dart:async';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../utils/camera_logger.dart';

class CameraControllerService {
  static final CameraControllerService _instance =
      CameraControllerService._internal();

  factory CameraControllerService() => _instance;

  CameraControllerService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool _isCapturing = false;

  final StreamController<bool> _initializationStreamController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _captureStreamController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();

  Stream<bool> get initializationStream =>
      _initializationStreamController.stream;

  Stream<bool> get captureStream => _captureStreamController.stream;

  Stream<String> get errorStream => _errorStreamController.stream;

  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  int get currentCameraIndex => _currentCameraIndex;

  FlashMode get currentFlashMode {
    if (_controller == null || !_isInitialized) return FlashMode.off;
    return _controller!.value.flashMode;
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    try {
      final currentMode = _controller!.value.flashMode;
      final nextMode = currentMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _controller!.setFlashMode(nextMode);
    } catch (e) {
      _errorStreamController.add('Failed to toggle flash: ${e.toString()}');
    }
  }

  // 🔥 FIXED INITIALIZATION
  Future<void> initializeCamera() async {
    if (_isInitialized) {
      _initializationStreamController.add(true);
      return;
    }

    try {
      CameraLogger.logInitializationStart();

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      for (var camera in _cameras) {
        try {
          _controller = CameraController(
            camera,
            ResolutionPreset.high,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

          await _controller!.initialize();
          await _controller!.setZoomLevel(1.0);

          _isInitialized = true;
          CameraLogger.logInitializationSuccess();
          _initializationStreamController.add(true);
          return;
        } catch (e) {
          CameraLogger.log('Failed to initialize camera: ${camera.name}');
        }
      }

      throw Exception('All cameras failed to initialize');
    } catch (e) {
      CameraLogger.logInitializationFailure(e.toString());
      _errorStreamController.add(
        'Camera initialization failed: ${e.toString()}',
      );
      _initializationStreamController.add(false);
    }
  }

  Future<void> initialize() async {
    await initializeCamera();
  }

  // 🔥 FIXED SWITCH CAMERA
  Future<void> switchCamera() async {
    if (!_isInitialized || _cameras.length <= 1) return;

    try {
      await _controller?.dispose();
      _isInitialized = false;
      _initializationStreamController.add(false);

      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

      _controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // 🔥 LOCK AGAIN AFTER SWITCH
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      double minZoom = await _controller!.getMinZoomLevel();
      await _controller!.setZoomLevel(minZoom);

      await _controller!.setFocusMode(FocusMode.auto);

      _isInitialized = true;
      _initializationStreamController.add(true);
    } catch (e) {
      _errorStreamController.add('Failed to switch camera: ${e.toString()}');
    }
  }

  Future<XFile?> captureImage() async {
    if (!_isInitialized || _isCapturing) return null;

    try {
      _isCapturing = true;
      _captureStreamController.add(true);

      final image = await _controller!.takePicture();
      return image;
    } catch (e) {
      _errorStreamController.add('Failed to capture image: ${e.toString()}');
      return null;
    } finally {
      _isCapturing = false;
      _captureStreamController.add(false);
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
    _errorStreamController.close();
  }
}
