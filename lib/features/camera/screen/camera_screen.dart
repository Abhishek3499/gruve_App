import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/camera_controller_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/capture_button.dart';
import '../widgets/top_bar.dart';
import '../widgets/side_toolbar.dart';
import '../widgets/mode_selector.dart';
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
    _initializeCamera();

    // Set portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

          Positioned(right: 16, top: 200, child: SideToolbar()),

          // Positioned(
          //   bottom: 140,
          //   left: 16,
          //   right: 16,
          //   child: BottomGalleryStrip(),
          // ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(child: CaptureButton()),
          ),

          Positioned(bottom: 40, left: 16, right: 16, child: ModeSelector()),
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
