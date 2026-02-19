import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controller/camera_controller_service.dart';
import '../utils/camera_logger.dart';

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget>
    with WidgetsBindingObserver {
  final CameraControllerService _cameraService = CameraControllerService();

  bool _isInitialized = false;
  String? _errorMessage;

  StreamSubscription<bool>? _initSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeListeners();
  }

  void _initializeListeners() {
    _initSub = _cameraService.initializationStream.listen((isInitialized) {
      if (!mounted) return;

      setState(() {
        _isInitialized = isInitialized;
        _errorMessage = null;
      });
    });

    _errorSub = _cameraService.errorStream.listen((error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error;
      });
    });
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

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
        ),
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initSub?.cancel();
    _errorSub?.cancel();
    CameraLogger.logVerbose('CameraPreviewWidget disposed');
    super.dispose();
  }
}
