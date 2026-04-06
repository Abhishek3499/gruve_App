import 'dart:async';

class VideoService {
  bool _isCompleted = false;
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  Stream<double> getProcessingProgress() async* {
    double progress = 0.0;
    while (progress <= 100 && !_isCompleted) {
      await Future.delayed(Duration(milliseconds: _getDelay(progress)));
      progress += 1;
      _progressController.add(progress);
      yield progress;
    }
    
    // Ensure we reach 100% when completed
    if (_isCompleted && progress < 100) {
      while (progress <= 100) {
        await Future.delayed(Duration(milliseconds: 50));
        progress += 5;
        if (progress > 100) progress = 100;
        _progressController.add(progress);
        yield progress;
      }
    }
  }

  void markCompleted() {
    _isCompleted = true;
    // Fast forward to 100%
    _progressController.add(100.0);
  }

  int _getDelay(double progress) {
    if (progress < 15) return 400; // Slow
    if (progress < 50) return 100; // Fast
    return 50; // Super fast
  }

  void dispose() {
    _progressController.close();
  }
}
