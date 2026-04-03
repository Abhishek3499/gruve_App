import 'package:flutter/foundation.dart';

enum CameraMode { story, groove }

/// Returned when the in-app camera pops after capture; mode is read at tap time.
class CameraCaptureResult {
  const CameraCaptureResult({
    required this.mediaPath,
    required this.mode,
  });

  final String mediaPath;
  final CameraMode mode;
}

class ModeService extends ChangeNotifier {
  static final ModeService _instance = ModeService._internal();
  factory ModeService() => _instance;
  ModeService._internal();

  CameraMode _selectedMode = CameraMode.story;

  CameraMode get selectedMode => _selectedMode;

  void setMode(CameraMode mode) {
    if (_selectedMode != mode) {
      _selectedMode = mode;
      notifyListeners();
    }
  }

  void setStoryMode() {
    setMode(CameraMode.story);
  }

  void setGrooveMode() {
    setMode(CameraMode.groove);
  }

  String get modeName {
    switch (_selectedMode) {
      case CameraMode.story:
        return 'Story';
      case CameraMode.groove:
        return 'Gruve';
    }
  }
}
