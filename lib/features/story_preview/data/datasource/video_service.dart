import 'dart:async';

class VideoService {
  // Simulated progress never reaches 100 on its own — only markCompleted()
  // (the real upload finishing) is allowed to do that. Past the cap we keep
  // creeping asymptotically toward it instead of freezing or ending the
  // stream, so a slow upload (e.g. video compression) still looks alive no
  // matter how long it actually takes.
  static const double _simulatedCap = 95.0;
  static const double _creepAsymptote = 99.0;
  static const double _creepFactor = 0.03;
  static const Duration _creepInterval = Duration(milliseconds: 400);

  bool _isCompleted = false;

  Stream<double> getProcessingProgress() async* {
    double progress = 0.0;
    while (progress < _simulatedCap && !_isCompleted) {
      await Future.delayed(Duration(milliseconds: _getDelay(progress)));
      if (_isCompleted) break;
      progress += 1.0;
      if (progress > _simulatedCap) progress = _simulatedCap;
      yield progress;
    }

    while (!_isCompleted) {
      await Future.delayed(_creepInterval);
      if (_isCompleted) break;
      progress += (_creepAsymptote - progress) * _creepFactor;
      yield progress;
    }

    // Ensure we yield 100% immediately when completed
    yield 100.0;
  }

  void markCompleted() {
    _isCompleted = true;
  }

  int _getDelay(double progress) {
    if (progress < 15) return 120; // Fast initial ticks
    if (progress < 50) return 40; // Very fast ticks
    return 15; // Super fast ticks
  }

  void dispose() {}
}
