import 'dart:async';

class VideoService {
  bool _isCompleted = false;
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  Stream<double> getProcessingProgress() async* {
    double progress = 0.0;
    while (progress <= 100 && !_isCompleted) {
      await Future.delayed(Duration(milliseconds: _getDelay(progress)));
      progress += 1.0;
      _progressController.add(progress);
      yield progress;
    }
    
    // Ensure we yield 100% immediately when completed
    if (_isCompleted) {
      _progressController.add(100.0);
      yield 100.0;
    }
  }

  void markCompleted() {
    _isCompleted = true;
    _progressController.add(100.0);
  }

  int _getDelay(double progress) {
    if (progress < 15) return 120; // Fast initial ticks
    if (progress < 50) return 40;  // Very fast ticks
    return 15; // Super fast ticks
  }

  void dispose() {
    _progressController.close();
  }
}
