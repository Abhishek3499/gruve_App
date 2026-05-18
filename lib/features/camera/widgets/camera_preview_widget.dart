import 'dart:async';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';

import '../controller/camera_controller_service.dart';

import '../utils/camera_logger.dart';
import 'dart:developer' as developer;



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
  
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;



  StreamSubscription<bool>? _initSub;

  StreamSubscription<String>? _errorSub;



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeListeners();

  }



  void _initializeListeners() {
    final initStart = DateTime.now();
    developer.log('📷 [PERF] Camera initialization started', name: 'CameraPreview');

    _initSub = _cameraService.initializationStream.listen((isInitialized) {

      if (!mounted) return;

      if (isInitialized) {
        final initTime = DateTime.now().difference(initStart);
        developer.log('📷 [PERF] Camera initialized in ${initTime.inMilliseconds}ms', name: 'CameraPreview');
        _initZoomLevels();
      }

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
  
  Future<void> _initZoomLevels() async {
    final controller = _cameraService.controller;
    if (controller != null && controller.value.isInitialized) {
      _maxZoom = await controller.getMaxZoomLevel();
      _minZoom = await controller.getMinZoomLevel();
      _currentZoom = _minZoom;
    }
  }
  
  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }
  
  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;
    
    double newZoom = _baseZoom * details.scale;
    newZoom = newZoom.clamp(_minZoom, _maxZoom);
    
    if ((newZoom - _currentZoom).abs() > 0.01) {
      _currentZoom = newZoom;
      await controller.setZoomLevel(_currentZoom);
      setState(() {});
    }
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



    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
          
          // Zoom indicator
          if (_currentZoom > _minZoom + 0.1)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

