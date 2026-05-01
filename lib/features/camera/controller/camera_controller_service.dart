import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../utils/camera_logger.dart';
import '../utils/image_filter_processor.dart';
import 'filter_controller.dart';

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
  bool _isRecordingVideo = false;

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

  Stream<bool> get initializationStream =>
      _initializationStreamController.stream;

  Stream<bool> get captureStream => _captureStreamController.stream;

  Stream<bool> get videoRecordingStream => _videoRecordingStreamController.stream;

  Stream<String> get errorStream => _errorStreamController.stream;

  Stream<FlashMode> get flashModeStream => _flashModeStreamController.stream;

  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isRecordingVideo => _isRecordingVideo;
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
      
      // Emit flash mode change to stream
      _flashModeStreamController.add(nextMode);
    } catch (e) {
      _errorStreamController.add('Failed to toggle flash: ${e.toString()}');
    }
  }

  // 🔥 OPTIMIZED INITIALIZATION
  Future<void> initializeCamera() async {
    if (_isInitialized) {
      _initializationStreamController.add(true);
      return;
    }

    try {
      CameraLogger.logInitializationStart();

      // Get cameras first
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Initialize first camera immediately
      final camera = _cameras.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true, // Enable audio for video recording
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize without delay
      await _controller!.initialize();
      await _controller!.setZoomLevel(1.0);

      _isInitialized = true;
      CameraLogger.logInitializationSuccess();
      _initializationStreamController.add(true);
    } catch (e) {
      CameraLogger.log('Failed to initialize camera: ${_cameras.first.name}');
      _errorStreamController.add('Camera initialization failed: ${e.toString()}');
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
        enableAudio: true, // Enable audio for video recording
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
    if (!_isInitialized || _isCapturing || _isRecordingVideo) return null;

    try {
      _isCapturing = true;
      _captureStreamController.add(true);

      final image = await _controller!.takePicture();
      
      // Get selected filter
      final filter = FilterController().selectedFilter;
      
      // If no matrix filter, return original image
      if (!filter.hasMatrix) {
        return image;
      }
      
      // Apply filter to image
      final File imageFile = File(image.path);
      
      // Resize large images to prevent memory issues
      final File processedFile = await ImageFilterProcessor.resizeImageIfNeeded(imageFile);
      
      // Apply color matrix filter
      final File filteredFile = await ImageFilterProcessor.applyColorMatrixToImage(
        processedFile,
        filter.matrix,
      );
      
      // Clean up temporary resized file if different from original
      if (processedFile.path != imageFile.path) {
        await processedFile.delete();
      }
      
      // Clean up original file
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

    try {
      _isRecordingVideo = true;
      _videoRecordingStreamController.add(true);
      
      await _controller!.startVideoRecording();
      CameraLogger.log('Video recording started');
    } catch (e) {
      _isRecordingVideo = false;
      _videoRecordingStreamController.add(false);
      _errorStreamController.add('Failed to start video recording: ${e.toString()}');
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!_isRecordingVideo) return null;

    try {
      final video = await _controller!.stopVideoRecording();
      CameraLogger.log('Video recording stopped: ${video.path}');
      return video;
    } catch (e) {
      _errorStreamController.add('Failed to stop video recording: ${e.toString()}');
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
  }
}
