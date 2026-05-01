import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../controller/camera_controller_service.dart';
import '../controller/filter_controller.dart';
import '../services/face_detection_service.dart';
import '../presentation/painters/glasses_painter.dart';
import '../utils/camera_logger.dart';

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget>
    with WidgetsBindingObserver {
  final CameraControllerService _cameraService = CameraControllerService();
  final FilterController _filterController = FilterController();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  bool _isInitialized = false;
  String? _errorMessage;
  List<Face> _faces = [];
  Size? _previewSize;

  StreamSubscription<bool>? _initSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<List<Face>>? _facesSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeListeners();
    _initializeFaceDetection();
  }

  Future<void> _initializeFaceDetection() async {
    await _faceDetectionService.initialize();
  }

  void _initializeListeners() {
    _initSub = _cameraService.initializationStream.listen((isInitialized) {
      if (!mounted) return;

      setState(() {
        _isInitialized = isInitialized;
        _errorMessage = null;
      });

      if (isInitialized) {
        _setupCameraStream();
      }
    });

    _errorSub = _cameraService.errorStream.listen((error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error;
      });
    });

    _facesSub = _faceDetectionService.facesStream.listen((faces) {
      if (!mounted) return;
      setState(() {
        _faces = faces;
      });
    });

    _filterController.addListener(_onFilterChanged);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: _buildPreview());
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

    _previewSize = controller.value.previewSize!;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _previewSize!.height,
              height: _previewSize!.width,
              child: ListenableBuilder(
                listenable: FilterController(),
                builder: (context, _) {
                  final filter = FilterController().selectedFilter;
                  
                  if (!filter.hasMatrix) {
                    // Normal filter - render CameraPreview directly
                    return CameraPreview(controller);
                  } else {
                    // Filter with matrix - wrap with ColorFiltered
                    return ColorFiltered(
                      colorFilter: ColorFilter.matrix(filter.matrix),
                      child: CameraPreview(controller),
                    );
                  }
                },
              ),
            ),
          ),
          if (_filterController.faceFilterEnabled && _faces.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _buildGlassesPainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

  void _setupCameraStream() {
    final controller = _cameraService.controller;
    if (controller != null) {
      controller.startImageStream(_processCameraImage);
    }
  }

  void _processCameraImage(CameraImage cameraImage) {
    final controller = _cameraService.controller;
    if (controller != null && _previewSize != null) {
      _faceDetectionService.processImage(cameraImage, controller.description);
    }
  }

  
  CustomPainter? _buildGlassesPainter() {
    if (_faces.isEmpty || _previewSize == null) return null;

    final primaryFace = _faceDetectionService.getPrimaryFace();
    if (primaryFace == null) return null;

    final screenSize = MediaQuery.of(context).size;
    final widgetSize = Size(screenSize.width, screenSize.height);

    return GlassesPainter(
      face: primaryFace,
      imageSize: Size(_previewSize!.height, _previewSize!.width),
      widgetSize: widgetSize,
    );
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initSub?.cancel();
    _errorSub?.cancel();
    _facesSub?.cancel();
    _filterController.removeListener(_onFilterChanged);
    
    final controller = _cameraService.controller;
    if (controller != null) {
      controller.stopImageStream();
    }
    
    _faceDetectionService.dispose();
    CameraLogger.logVerbose('CameraPreviewWidget disposed');
    super.dispose();
  }
}
