import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';

enum CameraMode { story, groove }

/// Returned when the in-app camera pops after capture; mode is read at tap time.
class CameraCaptureResult {
  const CameraCaptureResult({
    required this.mediaPath,
    required this.mode,
    this.stickers = const [],
  });

  final String mediaPath;
  final CameraMode mode;
  final List<StickerData> stickers;
}

class ModeService extends ChangeNotifier {
  static final ModeService _instance = ModeService._internal();
  factory ModeService() => _instance;
  ModeService._internal();

  CameraMode _selectedMode = CameraMode.story;
  final List<StickerData> _stickers = [];

  CameraMode get selectedMode => _selectedMode;
  List<StickerData> get stickers => _stickers;

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

  void addSticker(StickerData sticker) {
    _stickers.add(sticker);
    notifyListeners();
  }

  void removeSticker(String id) {
    _stickers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void updateSticker(String id, Offset position, double scale, double rotation) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stickers[index].position = position;
      _stickers[index].scale = scale;
      _stickers[index].rotation = rotation;
      notifyListeners();
    }
  }

  void clearStickers() {
    _stickers.clear();
    notifyListeners();
  }

  int _shootDuration = 0; // 0 means Off, or 5, 10 seconds
  int get shootDuration => _shootDuration;

  void setShootDuration(int duration) {
    _shootDuration = duration;
    notifyListeners();
  }

  bool _isCountdownRunning = false;
  bool get isCountdownRunning => _isCountdownRunning;

  int _countdownValue = 3;
  int get countdownValue => _countdownValue;

  void startCountdown(VoidCallback onFinished) {
    if (_isCountdownRunning) return;
    _isCountdownRunning = true;
    _countdownValue = 3;
    notifyListeners();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCountdownRunning) {
        timer.cancel();
        return;
      }
      _countdownValue--;
      if (_countdownValue == 0) {
        timer.cancel();
        _isCountdownRunning = false;
        notifyListeners();
        onFinished();
      } else {
        notifyListeners();
      }
    });
  }

  void cancelCountdown() {
    _isCountdownRunning = false;
    notifyListeners();
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
