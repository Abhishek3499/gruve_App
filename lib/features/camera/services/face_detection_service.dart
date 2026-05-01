import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import '../utils/camera_logger.dart';

class FaceDetectionService {
  static final FaceDetectionService _instance = FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;
  FaceDetectionService._internal();

  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  List<Face> _faces = [];
  final StreamController<List<Face>> _facesController = StreamController<List<Face>>.broadcast();

  Stream<List<Face>> get facesStream => _facesController.stream;
  List<Face> get currentFaces => List.unmodifiable(_faces);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      );

      _faceDetector = FaceDetector(options: options);
      _isInitialized = true;
      CameraLogger.log('Face detection service initialized');
    } catch (e) {
      CameraLogger.log('Failed to initialize face detection: $e');
      _isInitialized = false;
    }
  }

  Future<void> processImage(CameraImage cameraImage, CameraDescription camera) async {
    if (!_isInitialized || _faceDetector == null) return;

    try {
      final inputImage = _inputImageFromCameraImage(cameraImage, camera);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);
      _faces = faces;
      _facesController.add(faces);

      CameraLogger.logVerbose('Detected ${faces.length} faces');
    } catch (e) {
      CameraLogger.log('Face detection error: $e');
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage cameraImage, CameraDescription cameraDesc) {
    try {
      final sensorOrientation = cameraDesc.sensorOrientation;

      InputImageRotation? rotation;
      if (cameraDesc.lensDirection == CameraLensDirection.front) {
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation270deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation90deg;
            break;
          default:
            rotation = InputImageRotation.rotation90deg;
            break;
        }
      } else {
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation90deg;
            break;
        }
      }

      final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
      if (format == null) return null;

      final plane = cameraImage.planes.first;
      final bytes = plane.bytes;

      final imageMetadata = InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: imageMetadata);
    } catch (e) {
      CameraLogger.log('Error creating InputImage: $e');
      return null;
    }
  }

  Rect getFaceBoundingBox(Face face, Size imageSize, Size widgetSize) {
    final boundingBox = face.boundingBox;
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;

    return Rect.fromLTRB(
      boundingBox.left * scaleX,
      boundingBox.top * scaleY,
      boundingBox.right * scaleX,
      boundingBox.bottom * scaleY,
    );
  }

  bool hasValidFace() {
    if (_faces.isEmpty) return false;
    
    for (final face in _faces) {
      if (face.headEulerAngleY != null && 
          face.headEulerAngleY!.abs() < 30) {
        return true;
      }
    }
    return false;
  }

  Face? getPrimaryFace() {
    if (_faces.isEmpty) return null;
    
    Face? primaryFace;
    double largestArea = 0;
    
    for (final face in _faces) {
      final area = face.boundingBox.width * face.boundingBox.height;
      if (area > largestArea) {
        largestArea = area;
        primaryFace = face;
      }
    }
    
    return primaryFace;
  }

  void dispose() {
    _faceDetector?.close();
    _facesController.close();
    _isInitialized = false;
    CameraLogger.log('Face detection service disposed');
  }
}
