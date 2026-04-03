import 'dart:async';

class VideoService {
  // Simulating variable speeds
  Stream<double> getProcessingProgress() async* {
    double progress = 0.0;
    while (progress <= 100) {
      await Future.delayed(Duration(milliseconds: _getDelay(progress)));
      progress += 1;
      yield progress;
    }
  }

  int _getDelay(double progress) {
    if (progress < 15) return 400; // Slow
    if (progress < 50) return 100; // Fast
    return 50; // Super fast
  }
}
